json.extract! product, :id, :name, :slug, :description, :price, :compare_at_price, :sku, :stock_quantity, :track_inventory, :active, :featured,
              :created_at, :updated_at

json.category do
  json.extract! product.category, :id, :name, :slug if product.category
end

json.images do
  if product.images.attached?
    json.array! product.images do |image|
      json.id image.id
      json.url url_for(image)
      json.thumbnail_url url_for(image.variant(resize_to_limit: [300, 300]))
      json.filename image.filename.to_s
    end
  end
end

json.primary_image do
  if product.images.attached? && product.images.first
    json.url url_for(product.images.first)
    json.thumbnail_url url_for(product.images.first.variant(resize_to_limit: [300, 300]))
  end
end

json.on_sale product.on_sale?
json.discount_percentage product.discount_percentage if product.on_sale?
json.in_stock product.in_stock?

json.variants product.variants.active do |variant|
  json.id variant.id
  json.name variant.name
  json.price variant.price
  json.final_price variant.final_price
  json.stock_quantity variant.stock_quantity
  json.sku variant.sku
  json.active variant.active
  json.in_stock variant.in_stock?
end
