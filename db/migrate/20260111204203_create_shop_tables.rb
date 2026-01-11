class CreateShopTables < ActiveRecord::Migration[7.1]
  def change
    # Categorias de produtos
    create_table :shop_categories do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :shop_categories, [:account_id, :slug], unique: true

    # Produtos
    create_table :shop_products do |t|
      t.references :account, null: false, foreign_key: true
      t.references :shop_category, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :compare_at_price, precision: 10, scale: 2
      t.string :sku
      t.integer :stock_quantity, default: 0
      t.boolean :track_inventory, default: true
      t.boolean :active, default: true
      t.json :images, default: []
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :shop_products, [:account_id, :slug], unique: true
    add_index :shop_products, :sku

    # Variantes de produtos (tamanho, cor, etc)
    create_table :shop_product_variants do |t|
      t.references :shop_product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku
      t.decimal :price, precision: 10, scale: 2
      t.integer :stock_quantity, default: 0
      t.json :options, default: {}
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :shop_product_variants, :sku

    # Carrinhos
    create_table :shop_carts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :contact, foreign_key: true
      t.string :status, default: 'active'
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :shop_carts, [:account_id, :conversation_id]

    # Itens do carrinho
    create_table :shop_cart_items do |t|
      t.references :shop_cart, null: false, foreign_key: true
      t.references :shop_product, null: false, foreign_key: true
      t.references :shop_product_variant, foreign_key: true
      t.integer :quantity, default: 1, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.json :metadata, default: {}

      t.timestamps
    end

    # Pedidos
    create_table :shop_orders do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :order_number, null: false
      t.string :status, default: 'pending'
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      t.decimal :discount, precision: 10, scale: 2, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false
      t.text :customer_notes
      t.text :internal_notes
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :shop_orders, [:account_id, :order_number], unique: true
    add_index :shop_orders, :status

    # Itens do pedido
    create_table :shop_order_items do |t|
      t.references :shop_order, null: false, foreign_key: true
      t.references :shop_product, null: false, foreign_key: true
      t.references :shop_product_variant, foreign_key: true
      t.string :product_name, null: false
      t.string :variant_name
      t.integer :quantity, default: 1, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.json :metadata, default: {}

      t.timestamps
    end
  end
end
