class CreateChannelUazapi < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_uazapi do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false
      t.jsonb :provider_config, default: {}

      t.timestamps
    end

    add_index :channel_uazapi, :phone_number, unique: true
    add_index :channel_uazapi, :account_id
  end
end
