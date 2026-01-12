# == Schema Information
#
# Table name: shop_orders
#
#  id              :bigint           not null, primary key
#  account_id      :bigint           not null
#  conversation_id :bigint
#  contact_id      :bigint           not null
#  user_id         :bigint
#  order_number    :string           not null
#  status          :string           default("pending")
#  subtotal        :decimal(10, 2)   not null
#  discount        :decimal(10, 2)   default(0.0)
#  total           :decimal(10, 2)   not null
#  customer_notes  :text
#  internal_notes  :text
#  metadata        :json             default({})
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Shop::Order < ApplicationRecord
  self.table_name = 'shop_orders'

  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :contact
  belongs_to :user, optional: true
  has_many :items, class_name: 'Shop::OrderItem', foreign_key: 'shop_order_id', dependent: :destroy

  validates :order_number, presence: true, uniqueness: { scope: :account_id }
  validates :status, inclusion: { in: %w[pending confirmed processing shipped delivered cancelled] }
  validates :subtotal, :total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }

  def self.generate_order_number(account)
    date_prefix = Time.current.strftime('%Y%m%d')
    last_order = account.shop_orders.where('order_number LIKE ?', "#{date_prefix}%").order(:order_number).last

    sequence = if last_order
                 last_order.order_number.split('-').last.to_i + 1
               else
                 1
               end

    "#{date_prefix}-#{sequence.to_s.rjust(4, '0')}"
  end

  def confirm!
    update!(status: 'confirmed')
  end

  def cancel!
    transaction do
      # Devolver estoque
      items.each do |item|
        if item.variant
          item.variant.increment!(:stock_quantity, item.quantity)
        elsif item.product.track_inventory?
          item.product.increment!(:stock_quantity, item.quantity)
        end
      end

      update!(status: 'cancelled')
    end
  end

  def total_items
    items.sum(:quantity)
  end
end
