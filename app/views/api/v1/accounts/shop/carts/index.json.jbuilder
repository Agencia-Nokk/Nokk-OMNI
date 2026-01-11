json.array! @carts do |cart|
  json.id cart.id
  json.status cart.status
  json.subtotal cart.subtotal
  json.total_items cart.total_items
  
  json.contact do
    if cart.contact
      json.id cart.contact.id
      json.name cart.contact.name
    end
  end
  
  json.conversation do
    if cart.conversation
      json.id cart.conversation.id
      json.display_id cart.conversation.display_id
    end
  end
  
  json.items cart.items do |item|
    json.id item.id
    json.quantity item.quantity
    json.unit_price item.unit_price
    json.total_price item.total_price
    json.product do
      json.id item.product.id
      json.name item.product.name
      json.primary_image item.product.primary_image
    end
    if item.variant
      json.variant do
        json.id item.variant.id
        json.name item.variant.name
      end
    end
  end
  
  json.created_at cart.created_at
  json.updated_at cart.updated_at
end

