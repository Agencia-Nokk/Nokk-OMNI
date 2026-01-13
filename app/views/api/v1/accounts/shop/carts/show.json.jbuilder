json.id @cart.id
json.status @cart.status
json.subtotal @cart.subtotal
json.total_items @cart.total_items

json.contact do
  if @cart.contact
    json.id @cart.contact.id
    json.name @cart.contact.name
    json.email @cart.contact.email
    json.phone_number @cart.contact.phone_number
  end
end

json.conversation do
  if @cart.conversation
    json.id @cart.conversation.id
    json.display_id @cart.conversation.display_id
  end
end

json.items @cart.items do |item|
  json.id item.id
  json.quantity item.quantity
  json.unit_price item.unit_price
  json.total_price item.total_price
  
  json.product do
    json.id item.product.id
    json.name item.product.name
    json.price item.product.price
    json.primary_image item.product.primary_image
    json.images item.product.images
  end
  
  if item.variant
    json.variant do
      json.id item.variant.id
      json.name item.variant.name
      json.price item.variant.price
      json.options item.variant.options
    end
  end
end

json.created_at @cart.created_at
json.updated_at @cart.updated_at

