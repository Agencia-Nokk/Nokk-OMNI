class Uazapi::SendOnUazapiService < Base::SendOnChannelService
  MAX_RETRIES = 3
  RETRYABLE_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError].freeze

  private

  def channel_class
    Channel::Uazapi
  end

  def perform_reply
    return if message.content.blank? && message.attachments.blank?

    message_id = send_with_retry
    message.update!(source_id: message_id) if message_id.present?
  rescue StandardError => e
    message.update!(status: :failed, external_error: e.message)
    Rails.logger.error "[UAZAPI] Failed to send message after #{MAX_RETRIES} retries: #{e.message}"
  end

  def send_with_retry
    retries = 0
    begin
      channel.send_message(contact_phone_number, message)
    rescue *RETRYABLE_ERRORS => e
      retries += 1
      if retries <= MAX_RETRIES
        delay = 2**retries # 2s, 4s, 8s
        Rails.logger.warn "[UAZAPI] Retry #{retries}/#{MAX_RETRIES} after #{delay}s - #{e.class}: #{e.message}"
        sleep delay
        retry
      end
      raise
    end
  end

  def contact_phone_number
    contact_inbox.source_id
  end
end
