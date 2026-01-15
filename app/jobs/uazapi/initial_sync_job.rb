class Uazapi::InitialSyncJob < ApplicationJob
  queue_as :low

  def perform(channel_id)
    @channel = Channel::Uazapi.find_by(id: channel_id)
    return unless @channel&.inbox

    log 'Starting initial sync...'
    update_sync_status('syncing', 0, 0)

    sync_chats
    update_sync_status('completed', @total_synced, @total_chats)

    log "Initial sync completed! Synced #{@total_synced} contacts."
  rescue StandardError => e
    log "ERROR: #{e.class} - #{e.message}"
    update_sync_status('failed', @total_synced || 0, @total_chats || 0, e.message)
    raise
  end

  private

  def sync_chats
    @total_synced = 0
    @total_chats = 0
    offset = 0
    batch_size = 500

    loop do
      result = provider_service.fetch_chats(limit: batch_size, offset: offset)
      chats = result[:chats]
      pagination = result[:pagination]

      break if chats.empty?

      @total_chats = pagination['totalRecords'] || chats.length
      log "Fetched #{chats.length} chats (offset: #{offset}, total: #{@total_chats})"

      chats.each do |chat_data|
        sync_chat(chat_data)
        @total_synced += 1

        # Update progress every 50 contacts
        update_sync_status('syncing', @total_synced, @total_chats) if (@total_synced % 50).zero?
      end

      offset += batch_size
      break if offset >= @total_chats

      # Small delay to avoid rate limiting
      sleep 0.5
    end
  end

  def sync_chat(chat_data)
    chat_id = chat_data['wa_chatid'] || chat_data['id']
    return if chat_id.blank?

    is_group = chat_id.include?('@g.us')
    source_id = is_group ? chat_id : chat_id.gsub(/@.*/, '')

    # Get last message timestamp from chat data
    @current_chat_timestamp = extract_chat_timestamp(chat_data)

    # Check if contact already exists
    contact_inbox = @channel.inbox.contact_inboxes.find_by(source_id: source_id)
    if contact_inbox
      # If contact exists but no conversation, create one and sync messages
      sync_messages_for_contact_inbox(contact_inbox, chat_id)
      return
    end

    # Create contact
    contact = find_or_create_contact(chat_data, source_id, is_group)
    return unless contact

    # Create contact inbox
    contact_inbox = ContactInbox.create!(
      contact: contact,
      inbox: @channel.inbox,
      source_id: source_id
    )

    # Create conversation and sync messages
    sync_messages_for_contact_inbox(contact_inbox, chat_id)

    log "Synced: #{contact.name} (#{source_id})"
  rescue ActiveRecord::RecordNotUnique
    # Already exists, skip
  rescue StandardError => e
    log "Error syncing chat #{chat_id}: #{e.message}"
  end

  def extract_chat_timestamp(chat_data)
    # Try various fields that might contain the last message time
    timestamp = chat_data['lastMessageTime'] || chat_data['last_message_time'] ||
                chat_data['timestamp'] || chat_data['t'] || chat_data['muteExpiration']
    return Time.at(timestamp) if timestamp.is_a?(Integer) && timestamp.positive?

    1.year.ago # Default to 1 year ago for chats without timestamp
  end

  def sync_messages_for_contact_inbox(contact_inbox, chat_id)
    # Find or create conversation
    conversation = contact_inbox.conversations.first
    conversation ||= create_conversation(contact_inbox)
    return unless conversation

    # Fetch and import messages
    messages = provider_service.fetch_messages(chat_id, limit: 50)

    if messages.empty?
      # Mark conversation as having no history available
      conversation.update!(
        additional_attributes: (conversation.additional_attributes || {}).merge('uazapi_no_history' => true)
      )
      log "No messages available for #{contact_inbox.source_id}"
      return
    end

    import_messages(conversation, messages)

    # Update conversation last_activity_at to most recent message
    last_message = conversation.messages.order(created_at: :desc).first
    conversation.update!(last_activity_at: last_message.created_at) if last_message

    log "Imported #{messages.length} messages for #{contact_inbox.source_id}"
  rescue StandardError => e
    log "Error syncing messages for #{contact_inbox.source_id}: #{e.message}"
  end

  def create_conversation(contact_inbox)
    Conversation.create!(
      account: @channel.inbox.account,
      inbox: @channel.inbox,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox,
      status: :open,
      last_activity_at: @current_chat_timestamp || Time.current
    )
  end

  def import_messages(conversation, messages)
    # Sort by timestamp (oldest first)
    sorted_messages = messages.sort_by { |m| m['timestamp'] || 0 }

    sorted_messages.each do |msg_data|
      import_message(conversation, msg_data)
    end
  end

  def import_message(conversation, msg_data)
    message_id = extract_message_id(msg_data)
    return if message_id.blank?
    return if conversation.messages.exists?(source_id: message_id)

    content = msg_data['text'] || msg_data['caption'] || ''
    from_me = msg_data['fromMe'] == true
    timestamp = msg_data['timestamp']

    message = conversation.messages.create!(
      account: @channel.inbox.account,
      inbox: @channel.inbox,
      content: content,
      message_type: from_me ? :outgoing : :incoming,
      source_id: message_id,
      sender: from_me ? nil : conversation.contact,
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

    raw_id.include?(':') ? raw_id.split(':').last : raw_id
  end

  def has_media?(msg_data)
    type = (msg_data['type'] || msg_data['messageType'] || '').downcase
    media_type = (msg_data['mediaType'] || '').downcase
    %w[image video audio document sticker ptt media].any? { |t| type.include?(t) || media_type.include?(t) }
  end

  def import_media(message, msg_data)
    msg_id = extract_message_id(msg_data)
    return if msg_id.blank?

    response = HTTParty.post(
      "#{@channel.api_url}/message/download",
      headers: @channel.api_headers,
      body: { id: msg_id, return_link: true }.to_json
    )

    return unless response.success?

    body = JSON.parse(response.body)
    url = body['fileURL'] || body['url']
    return if url.blank?

    file = Down.download(url)
    file_type = determine_file_type(msg_data)

    message.attachments.create!(
      account_id: @channel.inbox.account_id,
      file_type: file_type,
      file: {
        io: file,
        filename: "#{file_type}_#{Time.current.to_i}#{mime_extension(msg_data)}",
        content_type: msg_data['mimetype'] || 'application/octet-stream'
      }
    )
  rescue StandardError => e
    log "Error importing media: #{e.message}"
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

  def find_or_create_contact(chat_data, source_id, is_group)
    if is_group
      create_group_contact(chat_data, source_id)
    else
      create_individual_contact(chat_data, source_id)
    end
  end

  def create_group_contact(chat_data, source_id)
    name = chat_data['wa_name'] || chat_data['name'] || "Grupo #{source_id.split('@').first[-6..]}"
    image_url = chat_data['imagePreview'] || chat_data['image']

    contact = Contact.find_or_create_by!(
      account: @channel.inbox.account,
      identifier: source_id
    ) do |c|
      c.name = name
      c.additional_attributes = {
        is_group: true,
        group_id: source_id,
        group_image_url: image_url
      }
    end

    attach_avatar(contact, image_url) if image_url.present? && !contact.avatar.attached?
    contact
  end

  def create_individual_contact(chat_data, source_id)
    phone = "+#{source_id.delete('+')}"
    name = chat_data['wa_name'] || chat_data['wa_contactName'] || chat_data['name'] || phone
    image_url = chat_data['imagePreview'] || chat_data['image']

    contact = Contact.find_or_create_by!(
      account: @channel.inbox.account,
      phone_number: phone
    ) do |c|
      c.name = name
      c.additional_attributes = { contact_image_url: image_url }
    end

    attach_avatar(contact, image_url) if image_url.present? && !contact.avatar.attached?
    contact
  end

  def attach_avatar(contact, image_url)
    file = Down.download(image_url)
    contact.avatar.attach(
      io: file,
      filename: "avatar_#{contact.id}.jpg",
      content_type: 'image/jpeg'
    )
  rescue StandardError => e
    log "Failed to download avatar: #{e.message}"
  end

  def update_sync_status(status, synced, total, error = nil)
    config = @channel.provider_config || {}
    config['sync_status'] = status
    config['sync_progress'] = { synced: synced, total: total }
    config['sync_error'] = error
    config['sync_updated_at'] = Time.current.iso8601
    @channel.update_column(:provider_config, config)

    # Broadcast update to frontend
    broadcast_sync_status(status, synced, total, error)
  end

  def broadcast_sync_status(status, synced, total, error)
    ActionCable.server.broadcast(
      "account_#{@channel.inbox.account_id}",
      {
        event: 'uazapi.sync_status',
        data: {
          account_id: @channel.inbox.account_id,
          inbox_id: @channel.inbox.id,
          status: status,
          synced: synced,
          total: total,
          error: error,
          percentage: total.positive? ? ((synced.to_f / total) * 100).round : 0
        }
      }
    )
  rescue StandardError => e
    log "Failed to broadcast: #{e.message}"
  end

  def provider_service
    @provider_service ||= Uazapi::ProviderService.new(channel: @channel)
  end

  def log(message)
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    File.open(Rails.root.join('log/uazapi_sync.log'), 'a') do |f|
      f.puts "[#{timestamp}] [InitialSync] #{message}"
    end
  end
end
