class Api::V1::Accounts::Shop::SettingsController < Api::V1::Accounts::BaseController
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
    params.require(:setting).permit(
      # Informações Básicas
      :name,
      :description,
      :logo,
      :banner,
      # Contato e Pedidos
      :whatsapp_number,
      :order_message_template,
      :contact_email,
      :business_hours,
      # Configurações de Exibição
      :enabled,
      :show_out_of_stock,
      :show_prices,
      :default_sort,
      :products_per_page,
      # Pedido Mínimo
      :minimum_order_value,
      :minimum_order_message,
      # Informações de Entrega
      :delivery_info,
      :delivery_areas,
      :pickup_info,
      # Aparência/Tema - Cores
      :primary_color,
      :background_color,
      :text_color,
      :secondary_color,
      # Aparência/Tema - Layout
      :header_style,
      :show_categories_bar,
      :products_per_row,
      :card_style,
      # Badge de Destaque
      :show_featured_badge,
      :featured_badge_text,
      # Informações Extras
      :address,
      :footer_text
    )
  end
end
