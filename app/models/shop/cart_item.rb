# == Schema Information
#
# Table name: shop_cart_items
#
#  id                      :bigint           not null, primary key
#  shop_cart_id            :bigint           not null
#  shop_product_id         :bigint           not null
#  shop_product_variant_id :bigint
#  quantity                :integer          default(1), not null
#  unit_price              :decimal(10, 2)   not null
#  metadata                :json             default({})
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class Shop::CartItem < ApplicationRecord
  self.table_name = 'shop_cart_items'

  belongs_to :cart, class_name: 'Shop::Cart', foreign_key: 'shop_cart_id'
  belongs_to :product, class_name: 'Shop::Product', foreign_key: 'shop_product_id'
  belongs_to :variant, class_name: 'Shop::ProductVariant', foreign_key: 'shop_product_variant_id', optional: true

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def total_price
    unit_price * quantity
  end

  def display_name
    variant ? "#{product.name} - #{variant.name}" : product.name
  end
end
