class AddFeaturedToShopProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :shop_products, :featured, :boolean, default: false, null: false
  end
end
