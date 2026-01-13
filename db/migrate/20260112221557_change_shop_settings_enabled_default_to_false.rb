class ChangeShopSettingsEnabledDefaultToFalse < ActiveRecord::Migration[7.0]
  def change
    change_column_default :shop_settings, :enabled, from: true, to: false
  end
end
