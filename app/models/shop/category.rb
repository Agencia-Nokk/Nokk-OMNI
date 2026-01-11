# == Schema Information
#
# Table name: shop_categories
#
#  id          :bigint           not null, primary key
#  account_id  :bigint           not null
#  name        :string           not null
#  slug        :string           not null
#  description :text
#  position    :integer          default(0)
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Shop::Category < ApplicationRecord
  belongs_to :account
  has_many :products, class_name: 'Shop::Product', foreign_key: 'shop_category_id', dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :account_id }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
