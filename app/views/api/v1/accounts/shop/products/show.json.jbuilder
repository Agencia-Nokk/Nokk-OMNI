json.id @product.id
json.name @product.name
json.slug @product.slug
json.description @product.description
json.price @product.price
json.compare_at_price @product.compare_at_price
json.on_sale @product.on_sale?
json.discount_percentage @product.discount_percentage
json.sku @product.sku
json.stock_quantity @product.stock_quantity
json.track_inventory @product.track_inventory
json.in_stock @product.in_stock?
json.active @product.active
json.images @product.images
json.primary_image @product.primary_image
json.metadata @product.metadata

json.category do
  if @product.category
    json.id @product.category.id
    json.name @product.category.name
    json.slug @product.category.slug
  end
end

json.variants @product.variants do |variant|
  json.id variant.id
  json.name variant.name
  json.sku variant.sku
  json.price variant.price
  json.final_price variant.final_price
  json.stock_quantity variant.stock_quantity
  json.in_stock variant.in_stock?
  json.options variant.options
  json.active variant.active
end

json.created_at @product.created_at
json.updated_at @product.updated_at

