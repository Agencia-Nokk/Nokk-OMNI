class Captain::Tools::Copilot::UpdateAutomationRuleService < Captain::Tools::BaseTool
  def self.name
    'update_automation_rule'
  end

  description <<~DESC
    Update an existing automation rule. You can update name, description, event, conditions, actions, or active status.

    **Important**: Before updating with assign_agent, assign_team, or execute_macro actions,
    use list_agents, list_teams, or list_macros respectively to get the correct IDs.

    Provide only the fields you want to update. Fields not provided will remain unchanged.
    For conditions and actions, provide the complete new array (it replaces the existing one).

    Example - Deactivate rule:
    { "rule_id": 1, "active": false }

    Example - Update name and description:
    { "rule_id": 1, "name": "New name", "description": "New description" }

    Example - Add execute_macro action:
    { "rule_id": 1, "actions": "[{\"action_name\": \"execute_macro\", \"action_params\": [macro_id]}]" }
  DESC

  param :rule_id, type: :integer, desc: 'ID of the automation rule to update', required: true
  param :name, type: 'string', desc: 'New name (optional)', required: false
  param :description, type: 'string', desc: 'New description (optional)', required: false
  param :event_name, type: 'string', desc: 'New event trigger (optional)', required: false
  param :conditions, type: 'string', desc: 'JSON string with new conditions (optional, replaces existing)', required: false
  param :actions, type: 'string', desc: 'JSON string with new actions (optional, replaces existing)', required: false
  param :active, type: 'boolean', desc: 'Whether the rule is active (optional)', required: false

  VALID_EVENTS = %w[conversation_created conversation_updated conversation_opened conversation_resolved message_created].freeze

  def execute(rule_id:, name: nil, description: nil, event_name: nil, conditions: nil, actions: nil, active: nil)
    rule = @assistant.account.automation_rules.find_by(id: rule_id)
    return "Automation rule with ID #{rule_id} not found" if rule.blank?

    updates = {}
    updates[:name] = name if name.present?
    updates[:description] = description if description.present?
    updates[:active] = active unless active.nil?

    if event_name.present?
      return "Invalid event_name. Valid: #{VALID_EVENTS.join(', ')}" unless VALID_EVENTS.include?(event_name)

      updates[:event_name] = event_name
    end

    if conditions.present?
      parsed_conditions = parse_json_param(conditions, 'conditions')
      return parsed_conditions if parsed_conditions.is_a?(String)

      normalized_conditions = normalize_conditions(parsed_conditions)
      return normalized_conditions if normalized_conditions.is_a?(String)

      updates[:conditions] = normalized_conditions
    end

    if actions.present?
      parsed_actions = parse_json_param(actions, 'actions')
      return parsed_actions if parsed_actions.is_a?(String)

      normalized_actions = normalize_actions(parsed_actions)
      return normalized_actions if normalized_actions.is_a?(String)

      updates[:actions] = normalized_actions
    end

    return 'No updates provided.' if updates.empty?

    rule.update!(updates)

    {
      'content' => "Automation rule '#{rule.name}' updated successfully",
      'entities' => [format_rule_entity(rule)]
    }
  end

  def format_rule_entity(rule)
    {
      'type' => 'automation_rule',
      'id' => rule.id,
      'name' => rule.name,
      'event' => rule.event_name,
      'active' => rule.active
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
      valid_attrs = rule.conditions_attributes + @assistant.account.custom_attribute_definitions.pluck(:attribute_key)
      return "Condition #{index + 1}: Invalid attribute_key '#{attribute_key}'" unless valid_attrs.include?(attribute_key)

      valid_operators = %w[equal_to not_equal_to contains does_not_contain is_present is_not_present starts_with]
      return "Condition #{index + 1}: Invalid filter_operator '#{filter_operator}'" unless valid_operators.include?(filter_operator)

      return "Condition #{index + 1}: query_operator is required (AND or OR)" if index.positive? && query_operator.blank?

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

      return "Invalid action '#{action_name}'. Valid: #{rule.actions_attributes.join(', ')}" unless rule.actions_attributes.include?(action_name)

      action_params = resolve_action_params(action_name, action[:action_params])
      return action_params if action_params.is_a?(String) && action_params.start_with?('Error:')

      { 'action_name' => action_name, 'action_params' => action_params }
    end
  end

  def resolve_action_params(action_name, params)
    case action_name
    when 'assign_agent'
      resolve_agent_param(params)
    when 'assign_team', 'send_email_to_team'
      resolve_team_param(params)
    else
      Array(params)
    end
  end

  def resolve_agent_param(params)
    return Array(params) if params.blank?

    param = params.first
    return [param] if param.is_a?(Integer) || param.to_s.match?(/^\d+$/)

    agent = @assistant.account.users.find_by('LOWER(name) = ? OR LOWER(email) = ?',
                                             param.to_s.downcase, param.to_s.downcase)
    return "Error: Agent '#{param}' not found. Use list_agents to see available agents." if agent.blank?

    [agent.id]
  end

  def resolve_team_param(params)
    return Array(params) if params.blank?

    param = params.first
    return [param.to_i] if param.is_a?(Integer) || param.to_s.match?(/^\d+$/)

    team = @assistant.account.teams.find_by('LOWER(name) = ?', param.to_s.downcase)
    return "Error: Team '#{param}' not found. Use list_teams to see available teams." if team.blank?

    [team.id]
  end
end
