class CreateShopSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }

      # 1. Informações Básicas
      t.string :name
      t.text :description
      # logo e banner serão Active Storage attachments

      # 2. Contato e Pedidos
      t.string :whatsapp_number
      t.text :order_message_template
      t.string :contact_email
      t.string :business_hours

      # 3. Configurações de Exibição
      t.boolean :enabled, default: true
      t.boolean :show_out_of_stock, default: true
      t.boolean :show_prices, default: true
      t.string :default_sort, default: 'newest'
      t.integer :products_per_page, default: 12

      # 4. Pedido Mínimo
      t.decimal :minimum_order_value, precision: 10, scale: 2
      t.string :minimum_order_message

      # 5. Informações de Entrega
      t.text :delivery_info
      t.text :delivery_areas
      t.text :pickup_info

      # 6. Aparência/Tema
      t.string :primary_color, default: '#1F93FF'
      t.string :header_style, default: 'minimal'
      t.boolean :show_categories_bar, default: true

      t.timestamps
    end
  end
end
