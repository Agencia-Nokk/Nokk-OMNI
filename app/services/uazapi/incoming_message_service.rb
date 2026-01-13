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

  def message_id
    message_data['messageid'] || message_data['id']
  end

  def phone_number
    # UAZAPI format: "558586736498@s.whatsapp.net" -> "558586736498"
    (message_data['chatid'] || message_data['sender'] || '').gsub(/@.*/, '')
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
    message_data['senderName'] || @params.dig('chat', 'name') || phone_number
  end

  def set_contact
    contact_inbox = inbox.contact_inboxes.find_by(source_id: phone_number)
    @contact = contact_inbox&.contact

    unless @contact
      @contact = Contact.create!(
        account: inbox.account,
        phone_number: "+#{phone_number}",
        name: sender_name
      )
      ContactInbox.create!(
        contact: @contact,
        inbox: inbox,
        source_id: phone_number
      )

      # Buscar foto e detalhes do contato em background
      Uazapi::ContactDetailsJob.perform_later(@contact.id, channel.id, phone_number)
    end

    @contact_inbox = inbox.contact_inboxes.find_by(source_id: phone_number)
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.open.last

    return if @conversation

    @conversation = Conversation.create!(
      account: inbox.account,
      inbox: inbox,
      contact: @contact,
      contact_inbox: @contact_inbox
    )
  end

  def create_message
    @message = @conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      content: message_content,
      message_type: :incoming,
      source_id: message_id,
      sender: @contact
    )
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
