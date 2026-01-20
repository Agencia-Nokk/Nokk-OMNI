class Captain::Tools::CreateAutomationRuleTool < Captain::Tools::BasePublicTool
  description <<~DESC
    Create a new automation rule (workflow) that triggers actions based on events and conditions. Automation rules help automate repetitive tasks and respond to specific conversation events automatically.
    
    **When to use:** Use this tool to create automated workflows that respond to events. For example: auto-labeling messages containing keywords, assigning conversations based on content, or sending automatic responses.
    
    **Complete Example:**
    To create a rule that auto-labels urgent messages:
    {
      "name": "Auto-label urgent messages",
      "description": "Automatically label and prioritize messages containing urgent keywords",
      "event_name": "message_created",
      "conditions": [
        {
          "attribute_key": "content",
          "filter_operator": "contains",
          "values": ["urgent", "asap", "emergency"],
          "query_operator": null
        },
        {
          "attribute_key": "message_type",
          "filter_operator": "equal_to",
          "values": [0],
          "query_operator": "AND"
        }
      ],
      "actions": [
        {"action_name": "add_label", "action_params": ["urgent"]},
        {"action_name": "change_priority", "action_params": ["high"]}
      ],
      "active": true
    }
    
    **Events (Triggers):**
    - conversation_created: Triggers when a new conversation is created
    - conversation_updated: Triggers when conversation properties change (status, assignee, etc.)
    - conversation_opened: Triggers when a snoozed/resolved conversation is reopened
    - conversation_resolved: Triggers when a conversation is marked as resolved
    - message_created: Triggers when a new message is posted in a conversation
    
    **Available Condition Attributes:**
    - content: Message content text
    - email: Contact email address
    - country_code: Country code of contact
    - status: Conversation status (open, resolved, pending)
    - message_type: Message type (0=incoming, 1=outgoing)
    - browser_language: Browser language
    - assignee_id: Assigned agent ID
    - team_id: Assigned team ID
    - referer: Referrer URL
    - city: Contact city
    - company: Contact company name
    - inbox_id: Inbox ID
    - mail_subject: Email subject
    - phone_number: Contact phone number
    - priority: Conversation priority (urgent, high, medium, low, none)
    - conversation_language: Conversation language
    - labels: Conversation labels
    
    **Filter Operators:**
    - equal_to: Exact match
    - not_equal_to: Not equal
    - contains: Contains text
    - does_not_contain: Does not contain text
    - is_present: Field has value
    - is_not_present: Field is empty
    - starts_with: Starts with text
    
    **Query Operators (for combining conditions):**
    - AND: All conditions must match
    - OR: Any condition can match
    - First condition doesn't need query_operator
    
    **Available Actions:**
    - send_message: Send public message. Params: ["message text"]
    - add_label: Add labels. Params: ["label1", "label2"]
    - remove_label: Remove labels. Params: ["label1", "label2"]
    - send_email_to_team: Email team members. Params: [team_id, "message"]
    - assign_team: Assign to team. Params: [team_id]
    - assign_agent: Assign to agent. Params: [agent_id]
    - send_webhook_event: Trigger webhook. Params: ["https://webhook.url"]
    - mute_conversation: Mute notifications. Params: []
    - send_attachment: Send file attachment. Params: [blob_id]
    - change_status: Change status. Params: ["open"|"resolved"|"pending"]
    - resolve_conversation: Mark resolved. Params: []
    - open_conversation: Reopen conversation. Params: []
    - snooze_conversation: Snooze conversation. Params: []
    - change_priority: Change priority. Params: ["urgent"|"high"|"medium"|"low"|"none"]
    - send_email_transcript: Send transcript via email. Params: ["email@example.com"]
    - add_private_note: Add private note. Params: ["note content"]
    
    **Common Use Cases:**
    1. Auto-label support requests: event="message_created", condition="content contains 'help'", action="add_label support"
    2. Assign VIP customers: event="conversation_created", condition="email contains '@vip.com'", action="assign_team [vip_team_id]"
    3. Auto-respond to keywords: event="message_created", condition="content contains 'refund'", action="send_message 'We process refunds within 5-7 business days'"
    4. Escalate urgent: event="message_created", condition="content contains 'urgent' AND priority equals 'none'", action="change_priority high, add_label urgent"
    
    Rules execute when the event occurs AND all conditions match. Actions run sequentially.
    For more details: https://www.chatwoot.com/hc/user-guide/articles/1677689800-how-to-use-automation
  DESC
  param :name, type: 'string', desc: 'A descriptive name for the automation rule'
  param :description, type: 'string', desc: 'Optional description explaining what the rule does', required: false
  param :event_name, type: 'string', desc: 'The event that triggers the rule: conversation_created, conversation_updated, conversation_opened, conversation_resolved, or message_created'
  param :conditions, type: 'string', desc: <<~CONDITIONS_DESC
    JSON string containing an array of condition objects. Each condition must have:
    - attribute_key: One of the available attributes (content, email, status, etc.)
    - filter_operator: One of the filter operators (equal_to, contains, is_present, etc.)
    - values: Array of values to match (can be empty for is_present/is_not_present)
    - query_operator: "AND" or "OR" (only needed for conditions after the first one)

    Example:
    [{"attribute_key": "content", "filter_operator": "contains", "values": ["urgent", "asap"], "query_operator": null}, {"attribute_key": "message_type", "filter_operator": "equal_to", "values": [0], "query_operator": "AND"}]
  CONDITIONS_DESC
  param :actions, type: 'string', desc: <<~ACTIONS_DESC
    JSON string containing an array of action objects. Each action must have:
    - action_name: One of the available action types listed in the tool description
    - action_params: Array of parameters for that action (can be empty array)

    Example:
    [{"action_name": "add_label", "action_params": ["urgent"]}, {"action_name": "change_priority", "action_params": ["high"]}, {"action_name": "send_message", "action_params": ["We've received your urgent request and will respond shortly."]}]

    Actions execute in the order provided.
  ACTIONS_DESC
  param :active, type: 'boolean', desc: 'Whether the rule is active (default: true)', required: false

  VALID_EVENTS = %w[conversation_created conversation_updated conversation_opened conversation_resolved message_created].freeze

  def perform(tool_context, name:, event_name:, conditions:, actions:, description: nil, active: true)
    return 'Rule name is required' if name.blank?
    return "Invalid event_name. Valid events: #{VALID_EVENTS.join(', ')}" unless VALID_EVENTS.include?(event_name)

    conditions = parse_json_param(conditions, 'conditions')
    return conditions if conditions.is_a?(String)

    actions = parse_json_param(actions, 'actions')
    return actions if actions.is_a?(String)

    normalized_conditions = normalize_conditions(conditions)
    return normalized_conditions if normalized_conditions.is_a?(String)

    normalized_actions = normalize_actions(actions)
    return normalized_actions if normalized_actions.is_a?(String)

    rule = create_automation_rule(name, event_name, normalized_conditions, normalized_actions, description, active)

    log_tool_usage('create_automation_rule', {
                     rule_id: rule.id,
                     name: name,
                     event_name: event_name,
                     conditions_count: normalized_conditions.size,
                     actions_count: normalized_actions.size
                   })

    "Automation rule '#{name}' created successfully (ID: #{rule.id}) with #{normalized_conditions.size} condition(s) and #{normalized_actions.size} action(s)"
  end

  private

  def parse_json_param(value, param_name)
    return value if value.is_a?(Array)

    JSON.parse(value)
  rescue JSON::ParserError
    "Invalid JSON for #{param_name}. Please provide a valid JSON array."
  end

  def normalize_conditions(conditions)
    return 'Conditions must be an array' unless conditions.is_a?(Array)
    return 'At least one condition is required' if conditions.empty?

    normalized = []
    conditions.each_with_index do |condition, index|
      condition = condition.with_indifferent_access
      attribute_key = condition[:attribute_key]
      filter_operator = condition[:filter_operator]
      values = condition[:values]
      query_operator = condition[:query_operator]

      return "Condition #{index + 1}: attribute_key is required" if attribute_key.blank?
      return "Condition #{index + 1}: filter_operator is required" if filter_operator.blank?

      rule = AutomationRule.new(account: @assistant.account)
      unless rule.conditions_attributes.include?(attribute_key) || @assistant.account.custom_attribute_definitions.pluck(:attribute_key).include?(attribute_key)
        return "Condition #{index + 1}: Invalid attribute_key '#{attribute_key}'. Valid: #{rule.conditions_attributes.join(', ')}"
      end

      valid_operators = %w[equal_to not_equal_to contains does_not_contain is_present is_not_present starts_with]
      unless valid_operators.include?(filter_operator)
        return "Condition #{index + 1}: Invalid filter_operator '#{filter_operator}'. Valid: #{valid_operators.join(', ')}"
      end

      if index > 0 && query_operator.blank?
        return "Condition #{index + 1}: query_operator is required (AND or OR)"
      end

      if query_operator.present? && !%w[AND OR].include?(query_operator.upcase)
        return "Condition #{index + 1}: query_operator must be 'AND' or 'OR'"
      end

      normalized << {
        'attribute_key' => attribute_key,
        'filter_operator' => filter_operator,
        'values' => Array(values || []),
        'query_operator' => index.zero? ? nil : query_operator&.upcase
      }
    end

    normalized
  end

  def normalize_actions(actions)
    return 'Actions must be an array' unless actions.is_a?(Array)
    return 'At least one action is required' if actions.empty?

    rule = AutomationRule.new(account: @assistant.account)
    actions.map do |action|
      action = action.with_indifferent_access
      action_name = action[:action_name]

      unless rule.actions_attributes.include?(action_name)
        return "Invalid action '#{action_name}'. Valid: #{rule.actions_attributes.join(', ')}"
      end

      { 'action_name' => action_name, 'action_params' => Array(action[:action_params]) }
    end
  end

  def create_automation_rule(name, event_name, conditions, actions, description, active)
    @assistant.account.automation_rules.create!(
      name: name,
      description: description,
      event_name: event_name,
      conditions: conditions,
      actions: actions,
      active: active
    )
  end
end
