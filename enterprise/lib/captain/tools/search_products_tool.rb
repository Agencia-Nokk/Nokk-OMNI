class Captain::Tools::SearchProductsTool < Captain::Tools::BasePublicTool
  description 'Search products in the shop catalog by name, description, or category'
  param :query, type: 'string', desc: 'Search term (product name or description)'
  param :category_id, type: 'integer', desc: 'Category ID to filter by (optional)', required: false
  param :in_stock_only, type: 'boolean', desc: 'Show only in-stock products (default: true)', required: false

  def perform(tool_context, query:, category_id: nil, in_stock_only: true)
    account = find_account(tool_context)
    return 'Account not found' unless account

    products = search_products(account, query, category_id, in_stock_only)

    log_tool_usage('search_products', {
                     query: query,
                     category_id: category_id,
                     in_stock_only: in_stock_only,
                     results_count: products.size
                   })

    format_results(products)
  end

  private

  def find_account(tool_context)
    conversation = find_conversation(tool_context.state)
    conversation&.account
  end

  def search_products(account, query, category_id, in_stock_only)
    scope = account.shop_products.active.includes(:category, images_attachments: :blob)
    scope = scope.in_stock if in_stock_only
    scope = scope.by_category(category_id) if category_id.present?

    scope.where(
      'LOWER(shop_products.name) LIKE :q OR LOWER(shop_products.description) LIKE :q',
      q: "%#{query.downcase}%"
    ).limit(10)
  end

  def format_results(products)
    return 'No products found matching your search.' if products.empty?

    lines = products.map { |p| format_product(p) }

    "Found #{products.size} product(s):\n\n#{lines.join("\n")}"
  end

  def format_product(product)
    stock_status = product.in_stock? ? '✅ In Stock' : '❌ Out of Stock'
    price_info = format_price(product)
    category_info = product.category&.name ? " (#{product.category.name})" : ''

    "- **#{product.name}**#{category_info}: #{price_info} - #{stock_status}"
  end

  def format_price(product)
    if product.on_sale?
      "~~R$ #{product.compare_at_price}~~ **R$ #{product.price}** (-#{product.discount_percentage}%)"
    else
      "R$ #{product.price}"
    end
  end
end
