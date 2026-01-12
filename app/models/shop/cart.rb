# == Schema Information
#
# Table name: shop_carts
#
#  id              :bigint           not null, primary key
#  account_id      :bigint           not null
#  conversation_id :bigint
#  contact_id      :bigint
#  status          :string           default("active")
#  metadata        :json             default({})
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Shop::Cart < ApplicationRecord
  self.table_name = 'shop_carts'

  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true
  has_many :items, class_name: 'Shop::CartItem', foreign_key: 'shop_cart_id', dependent: :destroy

  validates :status, inclusion: { in: %w[active converted abandoned] }

  scope :active, -> { where(status: 'active') }

  def add_item(product, quantity: 1, variant: nil)
    existing_item = items.find_by(shop_product_id: product.id, shop_product_variant_id: variant&.id)

    if existing_item
      existing_item.update(quantity: existing_item.quantity + quantity)
      existing_item
    else
      items.create!(
        shop_product_id: product.id,
        shop_product_variant_id: variant&.id,
        quantity: quantity,
        unit_price: variant&.final_price || product.price
      )
    end
  end

  def remove_item(item_id)
    items.find(item_id).destroy
  end

  def update_item_quantity(item_id, quantity)
    item = items.find(item_id)
    if quantity.positive?
      item.update(quantity: quantity)
    else
      item.destroy
    end
  end

  def subtotal
    items.sum { |item| item.unit_price * item.quantity }
  end

  def total_items
    items.sum(:quantity)
  end

  def convert_to_order!(user: nil, customer_notes: nil)
    transaction do
      order = Shop::Order.create!(
        account: account,
        conversation: conversation,
        contact: contact,
        user: user,
        order_number: Shop::Order.generate_order_number(account),
        subtotal: subtotal,
        total: subtotal,
        customer_notes: customer_notes,
        status: 'pending'
      )

      items.each do |cart_item|
        order.items.create!(
          shop_product_id: cart_item.shop_product_id,
          shop_product_variant_id: cart_item.shop_product_variant_id,
          product_name: cart_item.product.name,
          variant_name: cart_item.variant&.name,
          quantity: cart_item.quantity,
          unit_price: cart_item.unit_price,
          total_price: cart_item.unit_price * cart_item.quantity
        )
      end

      update!(status: 'converted')
      order
    end
  end
end
