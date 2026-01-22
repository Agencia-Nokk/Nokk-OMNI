json.id @order.id
json.order_number @order.order_number
json.status @order.status
json.subtotal @order.subtotal
json.discount @order.discount
json.total @order.total
json.total_items @order.total_items
json.customer_notes @order.customer_notes
json.internal_notes @order.internal_notes
json.metadata @order.metadata

json.contact do
  json.id @order.contact.id
  json.name @order.contact.name
  json.email @order.contact.email
  json.phone_number @order.contact.phone_number
end

json.conversation do
  if @order.conversation
    json.id @order.conversation.id
    json.display_id @order.conversation.display_id
  end
end

json.user do
  if @order.user
    json.id @order.user.id
    json.name @order.user.name
  end
end

json.items @order.items do |item|
  json.id item.id
  json.product_name item.product_name
  json.variant_name item.variant_name
  json.quantity item.quantity
  json.unit_price item.unit_price
  json.total_price item.total_price

  json.product do
    json.id item.product.id
    json.primary_image do
      if item.product.images.attached? && item.product.images.first
        json.url url_for(item.product.images.first)
        json.thumbnail_url url_for(item.product.images.first.variant(resize_to_limit: [300, 300]))
      end
    end
  end
end

json.created_at @order.created_at
json.updated_at @order.updated_at
