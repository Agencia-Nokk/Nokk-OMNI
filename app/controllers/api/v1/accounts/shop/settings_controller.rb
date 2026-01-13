class Api::V1::Accounts::Shop::SettingsController < Api::V1::Accounts::BaseController
  PERMITTED_PARAMS = %i[
    name description logo banner whatsapp_number order_message_template contact_email business_hours
    enabled show_out_of_stock show_prices default_sort products_per_page minimum_order_value
    minimum_order_message delivery_info delivery_areas pickup_info primary_color background_color
    text_color secondary_color header_style show_categories_bar products_per_row card_style
    show_featured_badge featured_badge_text address footer_text
  ].freeze

  before_action :set_setting

  def show; end

  def update
    if @setting.update(setting_params)
      render :show
    else
      render json: { errors: @setting.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_setting
    @setting = Current.account.shop_setting || Current.account.create_shop_setting!
  end

  def setting_params
    params.require(:setting).permit(*PERMITTED_PARAMS)
  end
end
