class Messages::InReplyToMessageBuilder
  pattr_initialize [:message!, :in_reply_to!, :in_reply_to_external_id!]

  delegate :conversation, to: :message

  def perform
    set_in_reply_to_attribute if @in_reply_to.present? || @in_reply_to_external_id.present?
  end

  private

  def set_in_reply_to_attribute
    reply_message = in_reply_to_message
    if reply_message
      # Found the message in the conversation - set both internal and external IDs
      @message.content_attributes[:in_reply_to_external_id] = reply_message.source_id
      @message.content_attributes[:in_reply_to] = reply_message.id
    elsif @in_reply_to_external_id.present?
      # Message not found but we have external ID - preserve it for display purposes
      # This is useful for WhatsApp/UAZAPI where we receive the external ID but
      # the original message might not exist in Chatwoot yet
      @message.content_attributes[:in_reply_to_external_id] ||= @in_reply_to_external_id
    end
  end

  def in_reply_to_message
    return conversation.messages.find_by(id: @in_reply_to) if @in_reply_to.present?

    return nil unless @in_reply_to_external_id

    # Try exact match first (new messages without owner prefix)
    conversation.messages.find_by(source_id: @in_reply_to_external_id) ||
      # Fallback: legacy messages saved with owner prefix (e.g., "551151992380:3EB0...")
      # Using split_part is more performant than LIKE
      conversation.messages.where("split_part(source_id, ':', 2) = ?", @in_reply_to_external_id).first
  end
end
