class Uazapi::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if message_already_processed?
    return if outgoing_message?

    set_contact
    set_conversation
    create_message
    attach_files if has_media?
  end

  private

  def channel
    @channel ||= inbox.channel
  end

  # UAZAPI sends message data in 'message' key, not 'data'
  def message_data
    @message_data ||= @params['message'] || @params['data'] || @params
  end

  def message_already_processed?
    inbox.messages.exists?(source_id: message_id)
  end

  def outgoing_message?
    message_data['fromMe'] == true
  end

  def group_message?
    message_data['isGroup'] == true || chat_id&.include?('@g.us')
  end

  def message_id
    message_data['messageid'] || message_data['id']
  end

  def chat_id
    message_data['chatid'] || message_data['chat_id']
  end

  # Source ID for ContactInbox - group ID or phone number
  def source_id
    if group_message?
      # For groups, use the full group ID (e.g., "120363422201326960@g.us")
      chat_id
    else
      # For individual chats, use just the phone number
      (chat_id || message_data['sender'] || '').gsub(/@.*/, '')
    end
  end

  # Phone number of the actual sender (person who sent the message)
  def sender_phone_number
    (message_data['sender'] || '').gsub(/@.*/, '')
  end

  def message_type
    # UAZAPI uses 'type' for media type (text, image, video, etc.)
    msg_type = message_data['type'] || message_data['messageType'] || 'text'
    msg_type.downcase
  end

  def message_content
    message_data['text'] || message_data['content'] || ''
  end

  def has_media?
    %w[image video audio document sticker ptt].include?(message_type)
  end

  def sender_name
    message_data['senderName'] || @params.dig('chat', 'name') || sender_phone_number
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

    # For groups, try to attach avatar if not already set
    update_group_avatar if group_message?

    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
  end

  def update_group_avatar
    return unless group_image_url.present?
    return if @contact.avatar.attached?

    Rails.logger.info "[UAZAPI] Downloading group avatar: #{group_image_url}"
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
    # Use find_or_create to handle cases where contact already exists
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
    contact = Contact.create!(
      account: inbox.account,
      phone_number: "+#{source_id}",
      name: sender_name
    )

    # Buscar foto e detalhes do contato em background
    Uazapi::ContactDetailsJob.perform_later(contact.id, channel.id, source_id)

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

  def create_message
    message_attrs = {
      account: inbox.account,
      inbox: inbox,
      content: message_content,
      message_type: :incoming,
      source_id: message_id,
      sender: @contact
    }

    # For group messages, store the actual sender info in content_attributes
    # so the frontend can display who sent the message
    if group_message?
      message_attrs[:content_attributes] = {
        group_sender_name: sender_name,
        group_sender_phone: sender_phone_number,
        is_group_message: true
      }
    end

    @message = @conversation.messages.create!(message_attrs)
  end

  def attach_files
    file_url = message_data['fileURL']
    return if file_url.blank?

    attachment_file = download_file(file_url)
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
  end

  def download_file(url)
    Down.download(url, headers: channel.api_headers)
  rescue Down::Error => e
    Rails.logger.error "[UAZAPI] Failed to download file: #{e.message}"
    nil
  end

  def attachment_file_type
    case message_type
    when 'image' then 'image'
    when 'video' then 'video'
    when 'audio' then 'audio'
    else 'file'
    end
  end

  def attachment_filename
    message_data['filename'] || "#{message_type}_#{Time.current.to_i}"
  end

  def attachment_content_type
    message_data['mimetype'] || 'application/octet-stream'
  end
end
