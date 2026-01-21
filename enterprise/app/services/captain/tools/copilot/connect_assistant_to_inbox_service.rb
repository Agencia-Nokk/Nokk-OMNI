class Captain::Tools::Copilot::ConnectAssistantToInboxService < Captain::Tools::BaseTool
  def self.name
    'connect_assistant_to_inbox'
  end

  description <<~DESC
    Connect a Captain Assistant to an Inbox so it can handle conversations automatically.

    Once connected, the assistant will automatically respond to new conversations in that inbox.

    Use list_assistants to find the assistant ID and list_inboxes to find the inbox ID.

    **Note:** Each inbox can only have one assistant connected at a time.
  DESC

  param :assistant_id, type: 'integer', desc: 'ID of the assistant to connect'
  param :inbox_id, type: 'integer', desc: 'ID of the inbox to connect to'

  def execute(assistant_id:, inbox_id:)
    target = find_assistant(assistant_id)
    return target if target.is_a?(String)

    inbox = find_inbox(inbox_id)
    return inbox if inbox.is_a?(String)

    existing_check = check_existing_connection(target, inbox)
    return existing_check if existing_check

    create_connection(target, inbox)
  end

  def active?
    true
  end

  private

  def find_assistant(assistant_id)
    target = @assistant.account.captain_assistants.find_by(id: assistant_id)
    target || "Assistant with ID #{assistant_id} not found. Use list_assistants to see available assistants."
  end

  def find_inbox(inbox_id)
    inbox = @assistant.account.inboxes.find_by(id: inbox_id)
    inbox || "Inbox with ID #{inbox_id} not found. Use list_inboxes to see available inboxes."
  end

  def check_existing_connection(target, inbox)
    existing = CaptainInbox.find_by(inbox_id: inbox.id, account_id: @assistant.account_id)
    return nil unless existing

    return already_connected_response(target, inbox) if existing.captain_assistant_id == target.id

    conflict_response(existing, inbox)
  end

  def already_connected_response(target, inbox)
    "Assistant '#{target.name}' is already connected to inbox '#{inbox.name}'."
  end

  def conflict_response(existing, inbox)
    existing_assistant = existing.captain_assistant
    {
      'content' => "Inbox '#{inbox.name}' is already connected to '#{existing_assistant.name}' (ID: #{existing_assistant.id}). Disconnect it first.",
      'entities' => [format_captain_inbox_entity(existing)]
    }
  end

  def create_connection(target, inbox)
    captain_inbox = CaptainInbox.create!(
      account_id: @assistant.account_id, inbox_id: inbox.id, captain_assistant_id: target.id
    )
    Rails.logger.info { "#{self.class.name}: connect assistant #{target.id} to inbox #{inbox.id}" }
    {
      'content' => "Assistant '#{target.name}' connected to inbox '#{inbox.name}' successfully.",
      'entities' => [format_captain_inbox_entity(captain_inbox)]
    }
  end

  def format_captain_inbox_entity(captain_inbox)
    {
      'type' => 'captain_inbox', 'id' => captain_inbox.id,
      'assistant_id' => captain_inbox.captain_assistant_id, 'inbox_id' => captain_inbox.inbox_id
    }
  end
end
