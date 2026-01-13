# == Schema Information
#
# Table name: shop_products
#
#  id                :bigint           not null, primary key
#  account_id        :bigint           not null
#  shop_category_id  :bigint
#  name              :string           not null
#  slug              :string           not null
#  description       :text
#  price             :decimal(10, 2)   not null
#  compare_at_price  :decimal(10, 2)
#  sku               :string
#  stock_quantity    :integer          default(0)
#  track_inventory   :boolean          default(TRUE)
#  active            :boolean          default(TRUE)
#  featured          :boolean          default(FALSE)
#  images            :json             default([])
#  metadata          :json             default({})
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Shop::Product < ApplicationRecord
  self.table_name = 'shop_products'

  belongs_to :account
  belongs_to :category, class_name: 'Shop::Category', foreign_key: 'shop_category_id', optional: true
  has_many :variants, class_name: 'Shop::ProductVariant', foreign_key: 'shop_product_id', dependent: :destroy
  has_many :cart_items, class_name: 'Shop::CartItem', foreign_key: 'shop_product_id', dependent: :destroy
  has_many :order_items, class_name: 'Shop::OrderItem', foreign_key: 'shop_product_id', dependent: :restrict_with_error

  has_many_attached :images
  accepts_nested_attributes_for :variants, allow_destroy: true

  validates :name, presence: true
  validate :images_count_within_limit
  validates :slug, presence: true, uniqueness: { scope: :account_id }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :track_inventory?

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :generate_sku, if: -> { sku.blank? }

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where('stock_quantity > 0 OR track_inventory = false') }
  scope :by_category, ->(category_id) { where(shop_category_id: category_id) }
  scope :featured, -> { where(featured: true) }

  def in_stock?
    !track_inventory || stock_quantity.positive?
  end

  def on_sale?
    compare_at_price.present? && compare_at_price > price
  end

  def discount_percentage
    return 0 unless on_sale?

    ((compare_at_price - price) / compare_at_price * 100).round
  end

  def primary_image
    images.first if images.attached?
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end

  def generate_sku
    self.sku = "PROD-#{SecureRandom.hex(4).upcase}"
  end

  def images_count_within_limit
    return unless images.attached? && images.count > 20

    errors.add(:images, 'Você pode adicionar no máximo 20 imagens')
  end
end
