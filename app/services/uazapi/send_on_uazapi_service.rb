class Uazapi::SendOnUazapiService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Uazapi
  end

  def perform_reply
    return if message.content.blank? && message.attachments.blank?

    message_id = channel.send_message(contact_phone_number, message)
    message.update!(source_id: message_id) if message_id.present?
  rescue StandardError => e
    message.update!(status: :failed, external_error: e.message)
    Rails.logger.error "[UAZAPI] Failed to send message: #{e.message}"
  end

  def contact_phone_number
    contact_inbox.source_id
  end
end
