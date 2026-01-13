# == Schema Information
#
# Table name: shop_settings
#
#  id                     :bigint           not null, primary key
#  account_id             :bigint           not null
#  name                   :string
#  description            :text
#  whatsapp_number        :string
#  order_message_template :text
#  contact_email          :string
#  business_hours         :string
#  enabled                :boolean          default(TRUE)
#  show_out_of_stock      :boolean          default(TRUE)
#  show_prices            :boolean          default(TRUE)
#  default_sort           :string           default("newest")
#  products_per_page      :integer          default(12)
#  minimum_order_value    :decimal(10, 2)
#  minimum_order_message  :string
#  delivery_info          :text
#  delivery_areas         :text
#  pickup_info            :text
#  primary_color          :string           default("#1F93FF")
#  header_style           :string           default("minimal")
#  show_categories_bar    :boolean          default(TRUE)
#  background_color       :string           default("#FFFFFF")
#  text_color             :string           default("#1F2937")
#  secondary_color        :string           default("#6B7280")
#  products_per_row       :integer          default(3)
#  card_style             :string           default("shadow")
#  show_featured_badge    :boolean          default(TRUE)
#  featured_badge_text    :string           default("Destaque")
#  address                :text
#  footer_text            :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Shop::Setting < ApplicationRecord
  self.table_name = 'shop_settings'

  belongs_to :account

  has_one_attached :logo
  has_one_attached :banner

  ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze

  validate :acceptable_logo
  validate :acceptable_banner

  validates :whatsapp_number, format: { with: /\A\+?\d{10,15}\z/ }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :products_per_page, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 48 }
  validates :minimum_order_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :primary_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true
  validates :background_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true
  validates :text_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true
  validates :secondary_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true
  validates :products_per_row, numericality: { only_integer: true, greater_than_or_equal_to: 2, less_than_or_equal_to: 4 }

  SORT_OPTIONS = %w[newest oldest price_asc price_desc name_asc name_desc].freeze
  HEADER_STYLES = %w[minimal with_banner].freeze
  CARD_STYLES = %w[shadow border minimal].freeze

  validates :default_sort, inclusion: { in: SORT_OPTIONS }
  validates :header_style, inclusion: { in: HEADER_STYLES }
  validates :card_style, inclusion: { in: CARD_STYLES }

  # Retorna o nome da loja ou fallback para nome da conta
  def display_name
    name.presence || account.name
  end

  # Retorna o número do WhatsApp formatado para URL
  def whatsapp_url_number
    return nil if whatsapp_number.blank?

    # Remove tudo que não é número
    whatsapp_number.gsub(/\D/, '')
  end

  # Verifica se a loja está habilitada
  def online?
    enabled?
  end

  # Retorna URL do logo ou nil
  def logo_url
    return nil unless logo.attached?

    Rails.application.routes.url_helpers.rails_blob_url(logo, only_path: true)
  end

  # Retorna URL do banner ou nil
  def banner_url
    return nil unless banner.attached?

    Rails.application.routes.url_helpers.rails_blob_url(banner, only_path: true)
  end

  private

  def acceptable_logo
    return unless logo.attached?

    return if ALLOWED_IMAGE_TYPES.include?(logo.content_type)

    errors.add(:logo, 'deve ser PNG, JPG, GIF ou WebP (SVG não é suportado)')
    logo.purge
  end

  def acceptable_banner
    return unless banner.attached?

    return if ALLOWED_IMAGE_TYPES.include?(banner.content_type)

    errors.add(:banner, 'deve ser PNG, JPG, GIF ou WebP (SVG não é suportado)')
    banner.purge
  end
end
