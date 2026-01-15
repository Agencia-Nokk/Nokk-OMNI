# rubocop:disable Metrics/ClassLength
class Uazapi::FetchHistoryService
  pattr_initialize [:conversation!, :limit]

  def perform
    return if already_has_messages?
    return unless uazapi_channel?

    log "Fetching history for conversation #{@conversation.id}"

    messages = fetch_messages
    return if messages.empty?

    import_messages(messages)
    log "Imported #{messages.length} messages"
  rescue StandardError => e
    log "ERROR: #{e.class} - #{e.message}"
    Rails.logger.error "[UAZAPI History] Error: #{e.message}"
  end

  private

  def already_has_messages?
    # Only fetch if conversation has no messages or just activity messages
    @conversation.messages.where.not(message_type: :activity).exists?
  end

  def uazapi_channel?
    channel.is_a?(Channel::Uazapi)
  end

  def fetch_messages
    chat_id = build_chat_id
    return [] if chat_id.blank?

    provider_service.fetch_messages(chat_id, limit: message_limit)
  end

  def build_chat_id
    source_id = @conversation.contact_inbox&.source_id
    return nil if source_id.blank?

    # Groups already have @g.us suffix
    return source_id if source_id.include?('@')

    # Individual chats need @s.whatsapp.net
    "#{source_id}@s.whatsapp.net"
  end

  def import_messages(messages)
    # Sort by timestamp (oldest first) to maintain order
    sorted_messages = messages.sort_by { |m| m['timestamp'] || 0 }

    sorted_messages.each do |msg_data|
      import_message(msg_data)
    end
  end

  def import_message(msg_data) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
    message_id = extract_message_id(msg_data)
    return if message_id.blank?
    return if @conversation.messages.exists?(source_id: message_id)

    content = extract_content(msg_data)
    from_me = msg_data['fromMe'] == true
    timestamp = msg_data['timestamp']

    message_attrs = {
      account: inbox.account,
      inbox: inbox,
      content: content,
      message_type: from_me ? :outgoing : :incoming,
      source_id: message_id,
      sender: from_me ? nil : @conversation.contact,
      created_at: timestamp ? Time.zone.at(timestamp) : Time.current
    }

    # Add interactive content_attributes if present
    interactive_attrs = build_interactive_attributes(msg_data)
    message_attrs[:content_attributes] = interactive_attrs if interactive_attrs.present?

    message = @conversation.messages.create!(message_attrs)

    # Import media if present
    import_media(message, msg_data) if has_media?(msg_data)
  rescue ActiveRecord::RecordNotUnique
    # Already imported
  rescue StandardError => e
    log "Error importing message #{message_id}: #{e.message}"
  end

  def extract_content(msg_data) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return msg_data['text'] if msg_data['text'].present?
    return msg_data['caption'] if msg_data['caption'].present?

    # Para mensagens interativas, extrair texto do body
    content = msg_data['content']
    return '' unless content.is_a?(Hash)

    interactive = content['InteractiveMessage'] || content['interactiveMessage']
    return '' unless interactive

    # Carrossel - pegar texto do primeiro card
    carousel = interactive['CarouselMessage'] || interactive['carouselMessage']
    if carousel
      first_card = carousel['cards']&.first
      return first_card&.dig('body', 'text') || ''
    end

    # Botões/Lista - pegar texto do body
    interactive.dig('body', 'text') || ''
  end

  def build_interactive_attributes(msg_data)
    content = msg_data['content']
    return {} unless content.is_a?(Hash)

    interactive = content['InteractiveMessage'] || content['interactiveMessage']
    return {} unless interactive

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

  def extract_message_id(msg_data)
    raw_id = msg_data['messageid'] || msg_data['id']
    return nil if raw_id.blank?

    # Remove owner prefix if present (format: "owner:messageid")
    raw_id.include?(':') ? raw_id.split(':').last : raw_id
  end

  def has_media?(msg_data) # rubocop:disable Naming/PredicateName
    type = (msg_data['type'] || msg_data['messageType'] || '').downcase
    media_type = (msg_data['mediaType'] || '').downcase
    media_types = %w[image video audio document sticker ptt media]
    media_types.include?(type) || media_types.include?(media_type)
  end

  def import_media(message, msg_data) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # Try to download media using UAZAPI's download endpoint
    msg_id = extract_message_id(msg_data)
    return if msg_id.blank?

    response = HTTParty.post(
      "#{channel.api_url}/message/download",
      headers: channel.api_headers,
      body: { id: msg_id, return_link: true }.to_json
    )

    return unless response.success?

    body = JSON.parse(response.body)
    url = body['fileURL'] || body['url']
    return if url.blank?

    file = Down.download(url)
    file_type = determine_file_type(msg_data)

    message.attachments.create!(
      account_id: inbox.account_id,
      file_type: file_type,
      file: {
        io: file,
        filename: "#{file_type}_#{Time.current.to_i}#{mime_extension(msg_data)}",
        content_type: msg_data['mimetype'] || 'application/octet-stream'
      }
    )
  rescue StandardError => e
    log "Error importing media for message #{message.id}: #{e.message}"
  end

  def determine_file_type(msg_data)
    type = (msg_data['mediaType'] || msg_data['type'] || '').downcase
    case type
    when 'image' then 'image'
    when 'video' then 'video'
    when 'audio', 'ptt' then 'audio'
    else 'file'
    end
  end

  def mime_extension(msg_data)
    mimetype = msg_data['mimetype'] || ''
    case mimetype
    when %r{image/jpeg} then '.jpg'
    when %r{image/png} then '.png'
    when %r{video/mp4} then '.mp4'
    when %r{audio/} then '.ogg'
    else ''
    end
  end

  def message_limit
    @limit || 20
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

  def log(message)
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    File.open(Rails.root.join('log/uazapi_sync.log'), 'a') do |f|
      f.puts "[#{timestamp}] [FetchHistory] #{message}"
    end
  end
end
# rubocop:enable Metrics/ClassLength
