json.extract! category, :id, :name, :slug, :description, :position, :active, :created_at, :updated_at
json.products_count category.products.count if category.respond_to?(:products)

json.image do
  if category.image.attached?
    json.url url_for(category.image)
    json.thumbnail_url url_for(category.image.variant(resize_to_limit: [300, 300]))
  end
end

