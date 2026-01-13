# == Schema Information
#
# Table name: shop_product_variants
#
#  id              :bigint           not null, primary key
#  shop_product_id :bigint           not null
#  name            :string           not null
#  sku             :string
#  price           :decimal(10, 2)
#  stock_quantity  :integer          default(0)
#  options         :json             default({})
#  active          :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Shop::ProductVariant < ApplicationRecord
  self.table_name = 'shop_product_variants'

  belongs_to :product, class_name: 'Shop::Product', foreign_key: 'shop_product_id', inverse_of: :variants
  has_many :cart_items, class_name: 'Shop::CartItem', foreign_key: 'shop_product_variant_id', dependent: :destroy, inverse_of: :variant
  has_many :order_items, class_name: 'Shop::OrderItem', foreign_key: 'shop_product_variant_id', dependent: :restrict_with_error, inverse_of: :variant

  validates :name, presence: true
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :generate_sku, if: -> { sku.blank? }

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where('stock_quantity > 0') }

  def in_stock?
    stock_quantity.positive?
  end

  def final_price
    price || product.price
  end

  private

  def generate_sku
    self.sku = "#{product.sku}-#{SecureRandom.hex(2).upcase}"
  end
end
