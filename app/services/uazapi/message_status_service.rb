class Uazapi::MessageStatusService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if message_ids.blank?

    message_ids.each do |msg_id|
      # UAZAPI sends message ID without the owner prefix, but we store with it
      message = find_message(msg_id)
      next unless message

      update_message_status(message)
    end
  end

  private

  def event_data
    @params['event'] || {}
  end

  def message_ids
    # UAZAPI sends MessageIDs as an array
    event_data['MessageIDs'] || []
  end

  def find_message(msg_id)
    # Try to find with full source_id (owner:messageid) or just messageid
    inbox.messages.find_by(source_id: msg_id) ||
      inbox.messages.where('source_id LIKE ?', "%:#{msg_id}").first ||
      inbox.messages.where('source_id LIKE ?', "%#{msg_id}%").first
  end

  def status
    # UAZAPI uses 'state' or 'event.Type' for status
    (@params['state'] || event_data['Type'] || '').downcase
  end

  def error_message
    @params['error'] || event_data['error'] || 'Unknown error'
  end

  def update_message_status(message)
    case status
    when 'sent'
      message.update!(status: :sent)
    when 'delivered'
      message.update!(status: :delivered)
    when 'read'
      message.update!(status: :read)
    when 'failed'
      message.update!(status: :failed, external_error: error_message)
    end
  end
end
