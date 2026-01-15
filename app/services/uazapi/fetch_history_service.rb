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

  def import_message(msg_data)
    message_id = extract_message_id(msg_data)
    return if message_id.blank?
    return if @conversation.messages.exists?(source_id: message_id)

    content = msg_data['text'] || msg_data['caption'] || ''
    from_me = msg_data['fromMe'] == true
    timestamp = msg_data['timestamp']

    message = @conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      content: content,
      message_type: from_me ? :outgoing : :incoming,
      source_id: message_id,
      sender: from_me ? nil : @conversation.contact,
      created_at: timestamp ? Time.at(timestamp) : Time.current
    )

    # Import media if present
    import_media(message, msg_data) if has_media?(msg_data)
  rescue ActiveRecord::RecordNotUnique
    # Already imported
  rescue StandardError => e
    log "Error importing message #{message_id}: #{e.message}"
  end

  def extract_message_id(msg_data)
    raw_id = msg_data['messageid'] || msg_data['id']
    return nil if raw_id.blank?

    # Remove owner prefix if present (format: "owner:messageid")
    raw_id.include?(':') ? raw_id.split(':').last : raw_id
  end

  def has_media?(msg_data)
    type = (msg_data['type'] || msg_data['messageType'] || '').downcase
    media_type = (msg_data['mediaType'] || '').downcase
    media_types = %w[image video audio document sticker ptt media]
    media_types.include?(type) || media_types.include?(media_type)
  end

  def import_media(message, msg_data)
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
