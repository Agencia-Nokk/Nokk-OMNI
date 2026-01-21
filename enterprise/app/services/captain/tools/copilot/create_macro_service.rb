class Captain::Tools::Copilot::CreateMacroService < Captain::Tools::BaseTool
  def self.name
    'create_macro'
  end

  description <<~DESC
    Create a new macro (automation workflow) with specified actions. Macros are sets of saved actions that help customer service agents complete tasks efficiently. When executed, macros run actions in sequence on conversations.

    **When to use:** Use this tool when you need to create a reusable set of actions that agents can execute with one click. For example: closing conversations, adding labels, sending follow-up messages, or updating priorities.

    **Complete Example:**
    To create a macro that labels urgent conversations and sends a confirmation message:
    {
      "name": "Mark urgent and confirm",
      "actions": [
        {"action_name": "add_label", "action_params": ["urgent"]},
        {"action_name": "change_priority", "action_params": ["high"]},
        {"action_name": "send_message", "action_params": ["We've received your urgent request and will respond shortly."]}
      ]
    }

    **Available actions and their parameters:**
    - send_message: Send a public message. Params: ["message text"]
    - add_label: Add a label to conversation. Params: ["label_name"]
    - remove_label: Remove a label from conversation. Params: ["label_name"]
    - assign_team: Assign conversation to a team. Params: [team_id]
    - assign_agent: Assign conversation to an agent. Params: [agent_id] or ["self"]
    - remove_assigned_team: Remove assigned team. Params: []
    - mute_conversation: Mute conversation notifications. Params: []
    - change_status: Change conversation status. Params: ["open"|"resolved"|"pending"]
    - resolve_conversation: Mark conversation as resolved. Params: []
    - snooze_conversation: Snooze conversation. Params: []
    - change_priority: Change conversation priority. Params: ["urgent"|"high"|"medium"|"low"|"none"]
    - send_email_transcript: Send conversation transcript via email. Params: ["email@example.com"]
    - add_private_note: Add internal private note. Params: ["note content"]
    - send_webhook_event: Trigger webhook event. Params: ["https://webhook.url"]

    **Common Use Cases:**
    1. Close conversation: [{"action_name": "add_label", "action_params": ["resolved"]}, {"action_name": "resolve_conversation", "action_params": []}]
    2. Escalate to team: [{"action_name": "assign_team", "action_params": [team_id]}, {"action_name": "change_priority", "action_params": ["high"]}]
    3. Send welcome message: [{"action_name": "send_message", "action_params": ["Welcome! How can I help you today?"]}]
    4. Add private note: [{"action_name": "add_private_note", "action_params": ["Customer requested callback"]}]

    Actions execute in the order provided. Macros created are global (visible to all agents).
    For more details, see: https://www.chatwoot.com/docs/product/features/macros
  DESC

  param :name, type: 'string', desc: 'A descriptive name for the macro (e.g., "Close and label urgent", "Send welcome message")'
  param :actions, type: 'string', desc: <<~ACTIONS_DESC
    JSON string containing an array of action objects. Each action must have:
    - action_name: One of the available action types listed in the tool description
    - action_params: Array of parameters for that action (can be empty array for actions with no params)

    Example:
    [{"action_name": "add_label", "action_params": ["urgent"]}, {"action_name": "change_priority", "action_params": ["high"]}, {"action_name": "resolve_conversation", "action_params": []}, {"action_name": "send_message", "action_params": ["Thank you for contacting us. This issue has been resolved."]}]

    Actions will execute in the order provided.
  ACTIONS_DESC

  def execute(name:, actions:)
    return 'Macro name is required' if name.blank?

    existing_macro = @assistant.account.macros.find_by('LOWER(name) = ?', name.downcase)
    if existing_macro.present?
      return {
        'content' => "A macro named '#{existing_macro.name}' already exists (ID: #{existing_macro.id}). " \
                     "Would you like to update the existing macro using the update_macro tool, or create a new one with a different name?",
        'entities' => [format_macro_entity(existing_macro)]
      }
    end

    parsed_actions = parse_json_param(actions, 'actions')
    return parsed_actions if parsed_actions.is_a?(String)

    normalized_actions = normalize_actions(parsed_actions)
    return normalized_actions if normalized_actions.is_a?(String)

    macro = create_macro(name, normalized_actions)

    Rails.logger.info do
      details = { macro_id: macro.id, name: name, actions_count: normalized_actions.size }
      "#{self.class.name}: create_macro for assistant #{@assistant&.id} - #{details.inspect}"
    end

    {
      'content' => "Macro '#{name}' created successfully with #{normalized_actions.size} action(s)",
      'entities' => [format_macro_entity(macro)]
    }
  end

  def format_macro_entity(macro)
    {
      'type' => 'macro',
      'id' => macro.id,
      'name' => macro.name,
      'visibility' => macro.visibility,
      'actions_count' => macro.actions.size
    }
  end

  def active?
    true
  end

  private

  def parse_json_param(value, param_name)
    return value if value.is_a?(Array)

    JSON.parse(value)
  rescue JSON::ParserError
    "Invalid JSON for #{param_name}. Please provide a valid JSON array."
  end

  def normalize_actions(actions)
    return 'Actions must be an array' unless actions.is_a?(Array)
    return 'At least one action is required' if actions.empty?

    actions.map do |action|
      action = action.with_indifferent_access
      action_name = action[:action_name]

      unless Macro::ACTIONS_ATTRS.include?(action_name)
        return "Invalid action '#{action_name}'. Valid: #{Macro::ACTIONS_ATTRS.join(', ')}"
      end

      { 'action_name' => action_name, 'action_params' => Array(action[:action_params]) }
    end
  end

  def create_macro(name, actions)
    @assistant.account.macros.create!(
      name: name,
      actions: actions,
      visibility: :global
    )
  end
end
