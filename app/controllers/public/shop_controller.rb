class Public::ShopController < ApplicationController
  layout 'public_shop'

  before_action :set_account
  before_action :set_shop_settings
  before_action :check_shop_enabled
  before_action :set_categories
  before_action :set_product, only: [:show]
  before_action :set_category, only: [:category]

  def index
    @products = base_products_query
  end

  def show; end

  def category
    @products = @category.products.active.includes(:category, images_attachments: :blob)
    @products = apply_product_filters(@products)
    render :index
  end

  def cart; end

  private

  def set_account
    # Busca por slug (nome parametrizado) ou por ID como fallback
    @account = Account.find_by('LOWER(name) = ?', params[:account_slug].tr('-', ' ').downcase)
    @account ||= Account.find_by(id: params[:account_slug])

    return if @account

    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

  def set_shop_settings
    @settings = @account.shop_setting || @account.create_shop_setting!
  end

  def check_shop_enabled
    return if @settings.enabled?

    render :unavailable, layout: false, status: :service_unavailable
  end

  def set_categories
    @categories = @account.shop_categories.active.ordered
    @categories = [] unless @settings.show_categories_bar?
  end

  def set_product
    @product = @account.shop_products.active.find_by!(slug: params[:product_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to public_shop_path(account_slug: account_slug_param), alert: 'Produto não encontrado'
  end

  def set_category
    @category = @account.shop_categories.active.find_by!(slug: params[:category_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to public_shop_path(account_slug: account_slug_param), alert: 'Categoria não encontrada'
  end

  def base_products_query
    products = @account.shop_products.includes(:category, images_attachments: :blob)
    products = products.active unless @settings.show_out_of_stock?
    apply_product_filters(products)
  end

  def apply_product_filters(products)
    products = apply_sorting(products)
    products.limit(@settings.products_per_page)
  end

  def apply_sorting(products)
    case @settings.default_sort
    when 'oldest'
      products.order(created_at: :asc)
    when 'price_asc'
      products.order(price: :asc)
    when 'price_desc'
      products.order(price: :desc)
    when 'name_asc'
      products.order(name: :asc)
    when 'name_desc'
      products.order(name: :desc)
    else # newest
      products.order(created_at: :desc)
    end
  end

  def account_slug_param
    @account.name.parameterize
  end
  helper_method :account_slug_param
end
