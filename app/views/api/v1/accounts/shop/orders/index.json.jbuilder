json.array! @orders do |order|
  json.id order.id
  json.order_number order.order_number
  json.status order.status
  json.subtotal order.subtotal
  json.discount order.discount
  json.total order.total
  json.total_items order.total_items
  
  json.contact do
    json.id order.contact.id
    json.name order.contact.name
    json.email order.contact.email
    json.phone_number order.contact.phone_number
  end
  
  json.conversation do
    if order.conversation
      json.id order.conversation.id
      json.display_id order.conversation.display_id
    end
  end
  
  json.user do
    if order.user
      json.id order.user.id
      json.name order.user.name
    end
  end
  
  json.created_at order.created_at
  json.updated_at order.updated_at
end

