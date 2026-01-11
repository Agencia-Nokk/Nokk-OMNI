json.array! @categories do |category|
  json.id category.id
  json.name category.name
  json.slug category.slug
  json.description category.description
  json.position category.position
  json.active category.active
  json.products_count category.products.count
  json.created_at category.created_at
  json.updated_at category.updated_at
end

