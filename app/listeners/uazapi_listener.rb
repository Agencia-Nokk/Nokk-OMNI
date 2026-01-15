class UazapiListener < BaseListener
  include Events::Types

  def conversation_typing_on(event)
    handle_typing_event(event, 'composing')
  end

  def conversation_typing_off(event)
    handle_typing_event(event, 'paused')
  end

  private

  def handle_typing_event(event, presence_type)
    conversation = event.data[:conversation]
    user = event.data[:user]
    is_private = event.data[:is_private]

    Rails.logger.info "[UAZAPI Typing] Event received - user: #{user.class}, is_private: #{is_private}"

    # Only send typing for non-private messages and when user is an agent (not contact)
    return if is_private
    return unless user.is_a?(User)

    inbox = conversation.inbox
    channel = inbox.channel

    # Only process for UAZAPI channels
    return unless channel.is_a?(Channel::Uazapi)

    # Get the contact's phone number
    contact_inbox = conversation.contact_inbox
    return if contact_inbox.blank?

    phone_number = contact_inbox.source_id
    return if phone_number.blank?

    Rails.logger.info "[UAZAPI Typing] Sending #{presence_type} to #{phone_number}"

    # Send presence to WhatsApp
    result = Uazapi::ProviderService.new(channel: channel).send_presence(phone_number, presence_type)
    Rails.logger.info "[UAZAPI Typing] Result: #{result}"
  end
end
