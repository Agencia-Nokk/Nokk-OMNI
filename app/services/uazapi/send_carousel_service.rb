class Uazapi::SendCarouselService
  pattr_initialize [:conversation!, :product_ids!, :text]

  def perform
    validation_error = validate_inputs
    return error_result(validation_error) if validation_error

    products = fetch_products
    return error_result(I18n.t('uazapi.shop.errors.no_products_found')) if products.empty?

    response = send_carousel(products)
    return error_result(response[:error]) unless response[:success]

    message = create_local_message(products, response[:message_id])
    { success: true, message: message }
  rescue StandardError => e
    Rails.logger.error "[UAZAPI Carousel] Error: #{e.message}"
    error_result(e.message)
  end

  private

  def error_result(error)
    { success: false, error: error }
  end

  def validate_inputs
    return I18n.t('uazapi.shop.errors.conversation_not_found') unless @conversation
    return I18n.t('uazapi.shop.errors.channel_not_uazapi') unless uazapi_channel?
    return I18n.t('uazapi.shop.errors.no_products_selected') if @product_ids.empty?
    return I18n.t('uazapi.shop.errors.max_products_exceeded') if @product_ids.length > 10

    nil
  end

  def uazapi_channel?
    channel.is_a?(Channel::Uazapi)
  end

  def fetch_products
    account.shop_products.where(id: @product_ids).includes(images_attachments: :blob)
  end

  def send_carousel(products)
    cards = products.map { |product| build_card(product) }

    provider_service.send_carousel(
      phone_number,
      text: carousel_text,
      cards: cards
    )
  end

  def build_card(product)
    {
      text: build_card_text(product),
      image: product_image_url(product),
      buttons: build_buttons(product)
    }
  end

  def build_card_text(product)
    lines = []
    lines << "*#{product.name}*"

    if product.description.present?
      lines << ''
      lines << product.description.to_s.truncate(80)
    end

    lines << ''
    lines << "💰 *#{format_price(product.price)}*"

    lines.join("\n")
  end

  def format_price(price)
    return I18n.t('uazapi.shop.price.consult') if price.blank? || price.zero?

    "R$ #{format('%.2f', price).tr('.', ',')}"
  end

  def product_image_url(product)
    return nil unless product.images.attached?

    first_image = product.images.first
    return nil unless first_image

    # Use base64 to avoid UAZAPI download latency
    product_image_base64(first_image)
  end

  def product_image_base64(image)
    content_type = image.content_type || 'image/jpeg'
    file_data = image.blob.open(&:read)
    "data:#{content_type};base64,#{Base64.strict_encode64(file_data)}"
  rescue StandardError => e
    Rails.logger.error "[UAZAPI Carousel] Base64 error: #{e.message}"
    nil
  end

  def product_image_url_original(product)
    return nil unless product.images.attached?

    first_image = product.images.first
    return nil unless first_image

    Rails.application.routes.url_helpers.rails_blob_url(
      first_image,
      host: frontend_url
    )
  end

  def build_buttons(product)
    [
      {
        id: product_shop_url(product),
        text: I18n.t('uazapi.shop.buttons.view_in_store'),
        type: 'URL'
      },
      {
        id: "ADD_CART_#{product.id}",
        text: I18n.t('uazapi.shop.buttons.add_to_cart'),
        type: 'REPLY'
      }
    ]
  end

  def product_shop_url(product)
    account_slug = account.name.parameterize
    "#{frontend_url}/loja/#{account_slug}/produto/#{product.slug}"
  end

  def carousel_text
    @text.presence || I18n.t('uazapi.shop.carousel.default_text')
  end

  def phone_number
    source_id = @conversation.contact_inbox&.source_id
    return source_id if source_id&.include?('@')

    "#{source_id}@s.whatsapp.net"
  end

  def create_local_message(products, source_id) # rubocop:disable Metrics/MethodLength
    # Use URL (not base64) for local message - Chatwoot can display from URL
    cards_data = products.map do |product|
      {
        body: "#{product.name}\n#{product_description(product)}",
        image_url: product_image_url_original(product),
        buttons: build_buttons(product).map do |btn|
          { type: btn[:type].downcase, display_text: btn[:text], id: btn[:id] }
        end
      }
    end

    @conversation.messages.create!(
      account: account,
      inbox: inbox,
      content: carousel_text,
      message_type: :outgoing,
      source_id: source_id,
      content_attributes: {
        interactive_type: 'carousel',
        interactive_data: { cards: cards_data }
      }
    )
  end

  def account
    @account ||= @conversation.account
  end

  def inbox
    @inbox ||= @conversation.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def provider_service
    @provider_service ||= Uazapi::ProviderService.new(channel: channel)
  end

  def frontend_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def product_description(product)
    product.description.to_s.truncate(80)
  end
end
