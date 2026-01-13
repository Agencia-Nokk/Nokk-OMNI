class AddCustomizationFieldsToShopSettings < ActiveRecord::Migration[7.1]
  def change
    # Cores
    add_column :shop_settings, :background_color, :string, default: '#FFFFFF'
    add_column :shop_settings, :text_color, :string, default: '#1F2937'
    add_column :shop_settings, :secondary_color, :string, default: '#6B7280'

    # Layout
    add_column :shop_settings, :products_per_row, :integer, default: 3
    add_column :shop_settings, :card_style, :string, default: 'shadow'

    # Badge de destaque
    add_column :shop_settings, :show_featured_badge, :boolean, default: true, null: false
    add_column :shop_settings, :featured_badge_text, :string, default: 'Destaque'

    # Informações extras
    add_column :shop_settings, :address, :text
    add_column :shop_settings, :footer_text, :text
  end
end
