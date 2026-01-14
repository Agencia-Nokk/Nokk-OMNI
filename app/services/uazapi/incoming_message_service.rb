class Uazapi::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if message_already_processed?
    return if sent_from_chatwoot?

    set_contact
    set_conversation
    create_message
    attach_files if media?
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

    # content can be a string or a hash (for media messages)
    content = message_data['content']
    content.is_a?(String) ? content : ''
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

  def set_contact
    contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
    @contact = contact_inbox&.contact

    unless @contact
      @contact = create_contact
      ContactInbox.create!(
        contact: @contact,
        inbox: inbox,
        source_id: source_id
      )
    end

    # Store sender_lid for presence/typing indicator lookup
    update_sender_lid if sender_lid.present?

    update_group_avatar if group_message?

    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
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
    return if group_image_url.blank? || @contact.avatar.attached?

    attach_group_avatar(@contact)
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
        group_id: source_id
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
    Contact.create!(account: inbox.account, phone_number: "+#{source_id}", name: contact_name).tap do |contact|
      Uazapi::ContactDetailsJob.perform_later(contact.id, channel.id, source_id)
    end
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

  def create_message
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

    message_attrs[:content_attributes] = content_attrs if content_attrs.present?

    @message = @conversation.messages.create!(message_attrs)

    # Log the saved content_attributes for debugging
    return unless quoted_message_id.present?

    Rails.logger.info "[UAZAPI] Message created with content_attributes: #{@message.content_attributes.inspect}"
    Rails.logger.info "[UAZAPI] in_reply_to: #{@message.content_attributes['in_reply_to'] || @message.content_attributes[:in_reply_to]}"
    Rails.logger.info "[UAZAPI] in_reply_to_external_id: #{@message.content_attributes['in_reply_to_external_id'] || @message.content_attributes[:in_reply_to_external_id]}"
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

  def fetch_media_url_from_uazapi
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
