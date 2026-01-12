json.extract! @setting,
              :id,
              :account_id,
              # Informações Básicas
              :name,
              :description,
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
              # Aparência/Tema
              :primary_color,
              :header_style,
              :show_categories_bar,
              # Timestamps
              :created_at,
              :updated_at

# URLs das imagens
json.logo_url @setting.logo.attached? ? url_for(@setting.logo) : nil
json.banner_url @setting.banner.attached? ? url_for(@setting.banner) : nil

# Nome de exibição (fallback para nome da conta)
json.display_name @setting.display_name

# URL da loja pública
json.public_url "/loja/#{@setting.account.name.parameterize}"
