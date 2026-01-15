# rubocop:disable Metrics/ClassLength
class Uazapi::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    log 'IncomingMessageService.perform started'
    log "message_id: #{message_id}, from_me: #{from_me?}, chat_id: #{chat_id}"
    log "message_type: #{message_type}, buttonOrListid: #{message_data['buttonOrListid']}"
    log "content: #{message_content.to_s.truncate(100)}"

    if message_already_processed?
      log 'Message already processed, skipping'
      return
    end

    if sent_from_chatwoot?
      log 'Message sent from chatwoot, skipping'
      return
    end

    log 'Setting contact...'
    set_contact
    log "Contact set: #{@contact&.id}"

    log 'Setting conversation...'
    set_conversation
    log "Conversation set: #{@conversation&.id}"

    log 'Creating message...'
    create_message
    log "Message created: #{@message&.id}"

    if media?
      log 'Attaching files...'
      attach_files
    end

    # Download high-quality images for carousel messages
    if carousel_message?
      log 'Downloading carousel images...'
      download_carousel_images
    end

    # Handle button responses
    handle_add_cart_response if add_cart_response?
    handle_view_cart if view_cart_response?
    handle_checkout if checkout_response?
    handle_clear_cart if clear_cart_response?

    log 'IncomingMessageService.perform completed!'
  rescue StandardError => e
    log "ERROR: #{e.class} - #{e.message}"
    log "Backtrace: #{e.backtrace&.first(5)&.join("\n")}"
    raise
  end

  def log(message)
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    File.open(Rails.root.join('log/uazapi_sse.log'), 'a') do |f|
      f.puts "[#{timestamp}] [IncomingMsg] #{message}"
    end
  end

  private

  def channel
    @channel ||= inbox.channel
  end

  def message_data
    @message_data ||= @params['message'] || @params['data'] || @params
  end

  def message_already_processed?
    inbox.messages.exists?(source_id: message_id)
  end

  def from_me?
    message_data['fromMe'] == true
  end

  def sent_from_chatwoot?
    # Messages sent from Chatwoot include track_source and track_id
    # These should be ignored to avoid duplicates
    return false unless from_me?

    track_source = message_data['track_source'] || @params['track_source']
    track_source == 'chatwoot'
  end

  def group_message?
    message_data['isGroup'] == true || chat_id&.include?('@g.us')
  end

  def message_id
    # UAZAPI sends 'messageid' (clean) and 'id' (with owner prefix like "551151992380:3EB0...")
    # Always use the clean messageid, or extract just the message part from id
    raw_id = message_data['messageid'] || message_data['id']
    return nil if raw_id.blank?

    # Remove owner prefix if present (format: "owner:messageid")
    raw_id.include?(':') ? raw_id.split(':').last : raw_id
  end

  def chat_id
    message_data['chatid'] || message_data['chat_id']
  end

  def source_id
    return chat_id if group_message?

    (chat_id || message_data['sender'] || '').gsub(/@.*/, '')
  end

  def sender_phone_number
    (message_data['sender'] || '').gsub(/@.*/, '')
  end

  def message_type
    (message_data['type'] || message_data['messageType'] || 'text').downcase
  end

  def media_type
    # UAZAPI sends mediaType separately (image, video, audio, document)
    (message_data['mediaType'] || '').downcase
  end

  def message_content
    text = message_data['text']
    return text if text.present?

    # Para respostas de botão, usar o buttonOrListid
    button_id = message_data['buttonOrListid'].to_s
    return format_button_response(button_id) if button_id.present?

    # Para mensagens interativas, extrair o texto do body
    return extract_interactive_text if interactive_message?

    # content can be a string or a hash (for media messages)
    content = message_data['content']
    content.is_a?(String) ? content : ''
  end

  def format_button_response(button_id)
    # Format ADD_CART buttons nicely
    if button_id.start_with?('ADD_CART_')
      product_id = button_id.gsub('ADD_CART_', '')
      product = inbox.account.shop_products.find_by(id: product_id)
      return "🛒 Adicionar ao Carrinho: #{product.name}" if product

      return '🛒 Adicionar ao Carrinho'
    end

    # Format other button responses
    case button_id
    when 'VIEW_CART'
      '🛒 Ver Carrinho'
    when 'CHECKOUT'
      '✅ Finalizar Pedido'
    when 'CLEAR_CART'
      '🗑️ Limpar Carrinho'
    else
      "📱 #{button_id}"
    end
  end

  def interactive_message?
    content = message_data['content']
    return false unless content.is_a?(Hash)

    content.key?('InteractiveMessage') || content.key?('interactiveMessage')
  end

  def carousel_message?
    return false unless interactive_message?

    content = message_data['content']
    interactive = content['InteractiveMessage'] || content['interactiveMessage'] || {}
    interactive.key?('CarouselMessage') || interactive.key?('carouselMessage')
  end

  def add_cart_response?
    button_id = message_data['buttonOrListid'].to_s
    button_id.start_with?('ADD_CART_')
  end

  def view_cart_response?
    button_id = message_data['buttonOrListid'].to_s
    button_id == 'VIEW_CART'
  end

  def checkout_response?
    button_id = message_data['buttonOrListid'].to_s
    button_id == 'CHECKOUT'
  end

  def clear_cart_response?
    button_id = message_data['buttonOrListid'].to_s
    button_id == 'CLEAR_CART'
  end

  def handle_add_cart_response
    # Check both buttonOrListid and message content for the ADD_CART ID
    button_id = message_data['buttonOrListid'].to_s
    cart_id = if button_id.start_with?('ADD_CART_')
                button_id
              else
                message_content.to_s
              end

    product_id = cart_id.gsub('ADD_CART_', '').to_i
    return if product_id.zero?

    log "Processing ADD_CART for product #{product_id}"

    product = inbox.account.shop_products.find_by(id: product_id)
    return unless product

    # Get or create cart for this conversation
    cart = Shop::Cart.find_or_create_by!(
      account: inbox.account,
      conversation: @conversation,
      contact: @contact,
      status: :active
    )

    # Add product to cart
    cart.add_item(product, quantity: 1)

    # Send confirmation message
    send_cart_confirmation(product, cart)
    log "Added product #{product.id} to cart #{cart.id}"
  rescue StandardError => e
    log "Error handling ADD_CART: #{e.message}"
  end

  def send_cart_confirmation(product, cart)
    subtotal = format('%.2f', cart.subtotal).tr('.', ',')
    item_text = cart.total_items == 1 ? 'item' : 'itens'

    text = "✅ *#{product.name}* adicionado!\n\n" \
           "🛒 *#{cart.total_items} #{item_text}* no carrinho\n" \
           "💰 Subtotal: *R$ #{subtotal}*"

    buttons = [
      { text: '🛒 Ver Carrinho', id: 'VIEW_CART', type: 'reply' },
      { text: '✅ Finalizar Pedido', id: 'CHECKOUT', type: 'reply' }
    ]

    # Send via UAZAPI with buttons
    provider_service = Uazapi::ProviderService.new(channel: inbox.channel)
    result = provider_service.send_buttons(
      phone_number,
      text: text,
      buttons: buttons
    )

    # Create local message to show in conversation
    @conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      content: text,
      message_type: :outgoing,
      source_id: result[:message_id]
    )
  end

  def phone_number
    @contact.phone_number&.gsub(/\D/, '') || @conversation.contact_inbox&.source_id&.gsub(/@.*/, '')
  end

  def handle_view_cart
    log 'Processing VIEW_CART'

    cart = Shop::Cart.find_by(
      account: inbox.account,
      conversation: @conversation,
      status: :active
    )

    unless cart&.items&.any?
      send_empty_cart_message
      return
    end

    send_cart_details(cart)
  rescue StandardError => e
    log "Error handling VIEW_CART: #{e.message}"
  end

  def handle_checkout
    log 'Processing CHECKOUT'

    cart = Shop::Cart.find_by(
      account: inbox.account,
      conversation: @conversation,
      status: :active
    )

    unless cart&.items&.any?
      send_empty_cart_message
      return
    end

    send_checkout_message(cart)
  rescue StandardError => e
    log "Error handling CHECKOUT: #{e.message}"
  end

  def handle_clear_cart
    log 'Processing CLEAR_CART'

    cart = Shop::Cart.find_by(
      account: inbox.account,
      conversation: @conversation,
      status: :active
    )

    if cart
      cart.items.destroy_all
      log "Cart #{cart.id} cleared"
    end

    text = "🗑️ Carrinho limpo!\n\nSeu carrinho foi esvaziado com sucesso."

    provider_service = Uazapi::ProviderService.new(channel: inbox.channel)
    provider_service.send_text(phone_number, text)

    @conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      content: text,
      message_type: :outgoing
    )
  rescue StandardError => e
    log "Error handling CLEAR_CART: #{e.message}"
  end

  def send_empty_cart_message
    text = "🛒 Seu carrinho está vazio!\n\nAdicione produtos para continuar."

    provider_service = Uazapi::ProviderService.new(channel: inbox.channel)
    provider_service.send_text(phone_number, text)

    @conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      content: text,
      message_type: :outgoing
    )
  end

  def send_cart_details(cart)
    items_text = cart.items.map do |item|
      price = format('%.2f', item.total_price).tr('.', ',')
      "• #{item.quantity}x #{item.product.name} - R$ #{price}"
    end.join("\n")

    subtotal = format('%.2f', cart.subtotal).tr('.', ',')

    text = "🛒 *Seu Carrinho*\n\n" \
           "#{items_text}\n\n" \
           "━━━━━━━━━━━━━━━\n" \
           "💰 *Total: R$ #{subtotal}*"

    buttons = [
      { text: '✅ Finalizar Pedido', id: 'CHECKOUT', type: 'reply' },
      { text: '🗑️ Limpar Carrinho', id: 'CLEAR_CART', type: 'reply' }
    ]

    provider_service = Uazapi::ProviderService.new(channel: inbox.channel)
    result = provider_service.send_buttons(
      phone_number,
      text: text,
      buttons: buttons
    )

    @conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      content: text,
      message_type: :outgoing,
      source_id: result[:message_id]
    )
  end

  def send_checkout_message(cart)
    items_text = cart.items.map do |item|
      price = format('%.2f', item.total_price).tr('.', ',')
      "• #{item.quantity}x #{item.product.name} - R$ #{price}"
    end.join("\n")

    subtotal = format('%.2f', cart.subtotal).tr('.', ',')

    text = "✅ *Finalizar Pedido*\n\n" \
           "#{items_text}\n\n" \
           "━━━━━━━━━━━━━━━\n" \
           "💰 *Total: R$ #{subtotal}*\n\n" \
           "Para confirmar seu pedido, por favor informe:\n" \
           "📍 Endereço de entrega\n" \
           '💳 Forma de pagamento'

    provider_service = Uazapi::ProviderService.new(channel: inbox.channel)
    provider_service.send_text(phone_number, text)

    @conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      content: text,
      message_type: :outgoing
    )
  end

  def download_carousel_images
    interactive_data = @message.content_attributes&.dig('interactive_data')
    return if interactive_data&.dig('cards').blank?

    updated_cards = interactive_data['cards'].map.with_index do |card, index|
      download_carousel_card_image(card, index)
    end

    # Update message with new image URLs
    new_content_attributes = @message.content_attributes.deep_dup
    new_content_attributes['interactive_data']['cards'] = updated_cards
    @message.update!(content_attributes: new_content_attributes)
    log "Updated #{updated_cards.count} carousel cards with images"
  rescue StandardError => e
    log "Error downloading carousel images: #{e.message}"
  end

  def download_carousel_card_image(card, index)
    # Skip if no image data available
    return card unless card['image_thumbnail'].present? || card['image_url'].present?

    # Try to download from URL first, then use thumbnail as fallback
    image_url = card['image_url']
    if image_url.present?
      begin
        file = Down.download(image_url)
        attachment = create_carousel_attachment(file, index, 'image/jpeg')
        return card.merge('image_attachment_url' => attachment_url(attachment)) if attachment
      rescue StandardError => e
        log "Failed to download card #{index} image from URL: #{e.message}"
      end
    end

    # If URL failed or not available, use base64 thumbnail (already works, just keep it)
    card
  rescue StandardError => e
    log "Error processing card #{index} image: #{e.message}"
    card
  end

  def create_carousel_attachment(file, index, content_type)
    @message.attachments.create!(
      account_id: inbox.account_id,
      file_type: 'image',
      file: {
        io: file,
        filename: "carousel_#{index}_#{Time.current.to_i}.jpg",
        content_type: content_type
      }
    )
  end

  def attachment_url(attachment)
    return nil unless attachment&.file&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      attachment.file,
      host: ENV.fetch('FRONTEND_URL', nil) || 'http://localhost:3000'
    )
  end

  def extract_interactive_text # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    content = message_data['content']
    interactive = content['InteractiveMessage'] || content['interactiveMessage'] || {}

    # Carrossel - pegar texto do primeiro card
    carousel = interactive['CarouselMessage'] || interactive['carouselMessage']
    if carousel
      first_card = carousel['cards']&.first
      return first_card&.dig('body', 'text') || ''
    end

    # Botões/Lista - pegar texto do body
    interactive.dig('body', 'text') || interactive.dig('NativeFlowMessage', 'body', 'text') || ''
  end

  def interactive_content_attributes
    return {} unless interactive_message?

    content = message_data['content']
    interactive = content['InteractiveMessage'] || content['interactiveMessage'] || {}

    {
      interactive_type: detect_interactive_type(interactive),
      interactive_data: parse_interactive_data(interactive)
    }
  end

  def detect_interactive_type(interactive) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return 'carousel' if interactive['CarouselMessage'] || interactive['carouselMessage']
    return 'list' if interactive['NativeFlowMessage']&.dig('buttons')&.any? { |b| b['name'] == 'single_select' }
    return 'buttons' if interactive['NativeFlowMessage'] || interactive['nativeFlowMessage']

    'unknown'
  end

  def parse_interactive_data(interactive) # rubocop:disable Metrics/CyclomaticComplexity
    carousel = interactive['CarouselMessage'] || interactive['carouselMessage']
    if carousel
      return {
        cards: carousel['cards']&.map { |card| parse_carousel_card(card) } || []
      }
    end

    native_flow = interactive['NativeFlowMessage'] || interactive['nativeFlowMessage']
    if native_flow
      return {
        body: interactive.dig('body', 'text'),
        buttons: parse_native_buttons(native_flow['buttons'])
      }
    end

    {}
  end

  def parse_carousel_card(card) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    inner_interactive = card['InteractiveMessage'] || card['interactiveMessage'] || {}
    native_flow = inner_interactive['NativeFlowMessage'] || inner_interactive['nativeFlowMessage'] || {}

    # Extrair imagem do header
    header = card['header'] || {}
    media = header['Media'] || header['media'] || {}
    image_msg = media['ImageMessage'] || media['imageMessage'] || {}

    {
      body: card.dig('body', 'text'),
      image_url: image_msg['url'],
      image_thumbnail: image_msg['jpegThumbnail'] || image_msg['JPEGThumbnail'],
      buttons: parse_native_buttons(native_flow['buttons'])
    }
  end

  def parse_native_buttons(buttons)
    return [] if buttons.blank?

    buttons.map do |btn|
      params = JSON.parse(btn['buttonParamsJson'] || btn['buttonParamsJSON'] || '{}')
      {
        type: btn['name'],
        display_text: params['display_text'],
        id: params['id'],
        url: params['url']
      }
    rescue JSON::ParserError
      { type: btn['name'], display_text: 'Button', id: nil }
    end
  end

  def media?
    # Check both type and mediaType fields
    media_types = %w[image video audio document sticker ptt media]
    media_types.include?(message_type) || media_types.include?(media_type)
  end

  def sender_name
    message_data['senderName'] || @params.dig('chat', 'name') || sender_phone_number
  end

  def contact_name
    # For outgoing messages, use chat name or phone number
    # For incoming messages, use sender name
    if from_me?
      @params.dig('chat', 'name') || source_id
    else
      sender_name
    end
  end

  def group_name
    @params.dig('chat', 'name') || message_data['groupName'] || "Grupo #{source_id.split('@').first[-6..]}"
  end

  def group_image_url
    @params.dig('chat', 'imagePreview') || @params.dig('chat', 'image')
  end

  def contact_image_url
    @params.dig('chat', 'imagePreview') || @params.dig('chat', 'image')
  end

  def contact_wa_name
    @params.dig('chat', 'wa_name') || @params.dig('chat', 'name')
  end

  def set_contact # rubocop:disable Metrics/MethodLength
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)

    unless @contact_inbox
      begin
        @contact = create_contact
        @contact_inbox = ContactInbox.create!(
          contact: @contact,
          inbox: inbox,
          source_id: source_id
        )
      rescue ActiveRecord::RecordNotUnique
        # Another job created the contact_inbox first (race condition)
        # Just fetch the one that was created
        @contact_inbox = inbox.contact_inboxes.find_by!(source_id: source_id)
      end
    end

    @contact ||= @contact_inbox.contact

    # Store sender_lid for presence/typing indicator lookup
    update_sender_lid if sender_lid.present?

    # Update avatar and name based on message type
    if group_message?
      update_group_avatar
    else
      update_contact_info
    end
  end

  def sender_lid
    # UAZAPI sends sender_lid which is needed for presence events
    lid = message_data['sender_lid'] || @params.dig('chat', 'wa_chatlid')
    lid&.gsub(/@.*/, '') # Remove @lid suffix
  end

  def update_sender_lid
    return if @contact.additional_attributes['whatsapp_lid'] == sender_lid

    @contact.additional_attributes['whatsapp_lid'] = sender_lid
    @contact.save!
  end

  def update_group_avatar
    return if group_image_url.blank?

    # Check if the image URL changed
    current_url = @contact.additional_attributes['group_image_url']
    return if current_url == group_image_url

    # Image changed! Update avatar
    @contact.avatar.purge if @contact.avatar.attached?
    attach_group_avatar(@contact)

    # Save the new URL to detect future changes
    @contact.additional_attributes['group_image_url'] = group_image_url
    @contact.save!
  end

  def update_contact_info
    changes_made = false

    # Update name if changed and we have a new name
    if contact_wa_name.present? && @contact.name != contact_wa_name
      @contact.name = contact_wa_name
      changes_made = true
    end

    # Update avatar if URL changed
    if contact_image_url.present?
      current_url = @contact.additional_attributes['contact_image_url']
      if current_url != contact_image_url
        @contact.avatar.purge if @contact.avatar.attached?
        attach_contact_avatar
        @contact.additional_attributes['contact_image_url'] = contact_image_url
        changes_made = true
      end
    end

    @contact.save! if changes_made
  end

  def attach_contact_avatar
    file = Down.download(contact_image_url)
    @contact.avatar.attach(
      io: file,
      filename: "contact_#{source_id}.jpg",
      content_type: 'image/jpeg'
    )
  rescue StandardError => e
    log "Failed to download contact avatar: #{e.message}"
  end

  def create_contact
    if group_message?
      create_group_contact
    else
      create_individual_contact
    end
  end

  def create_group_contact
    Contact.find_or_create_by!(
      account: inbox.account,
      identifier: source_id
    ) do |c|
      c.name = group_name
      c.additional_attributes = {
        is_group: true,
        group_id: source_id,
        group_image_url: group_image_url
      }
    end
  end

  def attach_group_avatar(contact)
    file = Down.download(group_image_url)
    contact.avatar.attach(
      io: file,
      filename: "group_#{source_id.split('@').first}.jpg",
      content_type: 'image/jpeg'
    )
    Rails.logger.info '[UAZAPI] Group avatar attached successfully!'
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Failed to download group avatar: #{e.class} - #{e.message}"
  end

  def create_individual_contact
    phone = "+#{source_id.delete('+')}"
    contact = Contact.find_or_create_by!(account: inbox.account, phone_number: phone) do |c|
      c.name = contact_name
    end
    # Fetch contact details in background (only for newly created contacts)
    Uazapi::ContactDetailsJob.perform_later(contact.id, channel.id, source_id) if contact.previously_new_record?
    contact
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.open.last

    return if @conversation

    @conversation = Conversation.create!(
      account: inbox.account,
      inbox: inbox,
      contact: @contact,
      contact_inbox: @contact_inbox,
      additional_attributes: group_message? ? { is_group: true } : {}
    )
  end

  def create_message # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    message_attrs = {
      account: inbox.account,
      inbox: inbox,
      content: message_content,
      message_type: from_me? ? :outgoing : :incoming,
      source_id: message_id
    }

    # For outgoing messages (sent from WhatsApp directly), don't set sender
    # For incoming messages, sender is the contact
    message_attrs[:sender] = @contact unless from_me?

    # Build content_attributes
    content_attrs = {}

    # For group messages, store the actual sender info
    if group_message?
      content_attrs[:group_sender_name] = sender_name
      content_attrs[:group_sender_phone] = sender_phone_number
      content_attrs[:is_group_message] = true
    end

    # For quoted replies, store the external ID of the quoted message
    content_attrs[:in_reply_to_external_id] = quoted_message_id if quoted_message_id.present?

    # For interactive messages (carousel, buttons, list), store the full structure
    content_attrs.merge!(interactive_content_attributes)

    message_attrs[:content_attributes] = content_attrs if content_attrs.present?

    @message = @conversation.messages.create!(message_attrs)

    # Log the saved content_attributes for debugging
    return if quoted_message_id.blank?

    Rails.logger.info "[UAZAPI] Message created with content_attributes: #{@message.content_attributes.inspect}"
    Rails.logger.info "[UAZAPI] in_reply_to: #{@message.content_attributes['in_reply_to'] || @message.content_attributes[:in_reply_to]}"
    external_id = @message.content_attributes['in_reply_to_external_id'] || @message.content_attributes[:in_reply_to_external_id]
    Rails.logger.info "[UAZAPI] in_reply_to_external_id: #{external_id}"
  end

  def quoted_message_id
    # UAZAPI sends the quoted message ID in the 'quoted' field
    quoted_id = message_data['quoted'].presence
    if quoted_id.present?
      Rails.logger.info "[UAZAPI] Found quoted message ID: #{quoted_id}"
      # Check if the quoted message exists in this conversation
      existing = @conversation&.messages&.find_by(source_id: quoted_id)
      Rails.logger.info "[UAZAPI] Quoted message found in DB: #{existing&.id || 'NOT FOUND'}"
    end
    quoted_id
  end

  def attach_files
    # Use UAZAPI's /message/download endpoint to get a public URL
    download_url = fetch_media_url_from_uazapi
    return if download_url.blank?

    Rails.logger.info "[UAZAPI] Downloading media from: #{download_url[0..100]}..."

    attachment_file = download_file(download_url)
    return unless attachment_file

    @message.attachments.create!(
      account_id: inbox.account_id,
      file_type: attachment_file_type,
      file: {
        io: attachment_file,
        filename: attachment_filename,
        content_type: attachment_content_type
      }
    )
    Rails.logger.info '[UAZAPI] Media attachment created successfully!'
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Failed to create attachment: #{e.message}"
    Rails.logger.error e.backtrace&.first(5)&.join("\n")
  end

  def fetch_media_url_from_uazapi # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # UAZAPI requires calling /message/download to get a public URL for encrypted WhatsApp media
    msg_id = message_id
    return nil if msg_id.blank?

    Rails.logger.info "[UAZAPI] Fetching media URL for message: #{msg_id}"

    response = HTTParty.post(
      "#{channel.api_url}/message/download",
      headers: channel.api_headers,
      body: {
        id: msg_id,
        return_link: true
      }.to_json
    )

    if response.success?
      body = JSON.parse(response.body)
      url = body['fileURL'] || body['url']
      Rails.logger.info "[UAZAPI] Got media URL: #{url&.slice(0, 80)}"
      url
    else
      Rails.logger.error "[UAZAPI] Failed to fetch media URL: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error fetching media URL: #{e.message}"
    nil
  end

  def download_file(url)
    Down.download(url)
  rescue Down::Error => e
    Rails.logger.error "[UAZAPI] Failed to download file (Down): #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Failed to download file: #{e.class} - #{e.message}"
    nil
  end

  def attachment_file_type
    type = media_type.presence || message_type
    case type
    when 'image' then 'image'
    when 'video' then 'video'
    when 'audio', 'ptt' then 'audio'
    else 'file'
    end
  end

  def attachment_filename
    ext = mime_extension
    base = "#{attachment_file_type}_#{Time.current.to_i}"
    message_data['filename'] || "#{base}#{ext}"
  end

  def attachment_content_type
    content = message_data['content']
    return content['mimetype'] if content.is_a?(Hash) && content['mimetype'].present?

    message_data['mimetype'] || 'application/octet-stream'
  end

  def mime_extension
    case attachment_content_type
    when %r{image/jpeg} then '.jpg'
    when %r{image/png} then '.png'
    when %r{video/mp4} then '.mp4'
    when %r{audio/} then '.ogg'
    else ''
    end
  end
end
# rubocop:enable Metrics/ClassLength
