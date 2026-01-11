# == Schema Information
#
# Table name: shop_order_items
#
#  id                      :bigint           not null, primary key
#  shop_order_id           :bigint           not null
#  shop_product_id         :bigint           not null
#  shop_product_variant_id :bigint
#  product_name            :string           not null
#  variant_name            :string
#  quantity                :integer          default(1), not null
#  unit_price              :decimal(10, 2)   not null
#  total_price             :decimal(10, 2)   not null
#  metadata                :json             default({})
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class Shop::OrderItem < ApplicationRecord
  belongs_to :order, class_name: 'Shop::Order', foreign_key: 'shop_order_id'
  belongs_to :product, class_name: 'Shop::Product', foreign_key: 'shop_product_id'
  belongs_to :variant, class_name: 'Shop::ProductVariant', foreign_key: 'shop_product_variant_id', optional: true

  validates :product_name, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_total_price, if: -> { unit_price.present? && quantity.present? }

  def display_name
    variant_name ? "#{product_name} - #{variant_name}" : product_name
  end

  private

  def set_total_price
    self.total_price = unit_price * quantity
  end
end
