class Uazapi::PresenceService
  include Events::Types

  pattr_initialize [:inbox!, :params!]

  def perform
    Rails.logger.info "[UAZAPI Presence] Starting - lid: #{whatsapp_lid}, state: #{presence_type}"

    return if presence_data.blank?

    set_conversation

    if @conversation.blank?
      Rails.logger.info "[UAZAPI Presence] No conversation found for lid: #{whatsapp_lid}"
      return
    end

    Rails.logger.info "[UAZAPI Presence] Found conversation #{@conversation.id} - triggering #{typing? ? 'TYPING_ON' : 'TYPING_OFF'}"
    trigger_typing_event
  end

  private

  def presence_data
    # UAZAPI sends presence data in 'event' key
    @presence_data ||= @params['event'] || @params['data'] || @params
  end

  def chat_id
    # UAZAPI uses 'Chat' or 'Sender' with @lid format
    presence_data['Chat'] || presence_data['Sender'] || presence_data['chatid'] || presence_data['from']
  end

  def whatsapp_lid
    # Extract the lid number (remove @lid suffix)
    chat_id&.gsub(/@.*/, '')
  end

  def presence_type
    # UAZAPI uses 'State' for presence status
    # Values: 'composing', 'paused', 'available', 'unavailable', 'recording'
    presence_data['State'] || presence_data['type'] || presence_data['presence'] || presence_data['status']
  end

  def typing?
    %w[composing recording typing].include?(presence_type&.downcase)
  end

  def set_conversation
    return if whatsapp_lid.blank?

    # Find contact by whatsapp_lid stored in additional_attributes
    @contact = inbox.account.contacts.find_by("additional_attributes->>'whatsapp_lid' = ?", whatsapp_lid)
    return if @contact.blank?

    contact_inbox = @contact.contact_inboxes.find_by(inbox: inbox)
    return if contact_inbox.blank?

    @conversation = contact_inbox.conversations.open.last
  end

  def trigger_typing_event
    return if @conversation.blank? || @contact.blank?

    event_name = typing? ? CONVERSATION_TYPING_ON : CONVERSATION_TYPING_OFF

    Rails.configuration.dispatcher.dispatch(
      event_name,
      Time.zone.now,
      conversation: @conversation,
      user: @contact,
      is_private: false
    )
  end
end
