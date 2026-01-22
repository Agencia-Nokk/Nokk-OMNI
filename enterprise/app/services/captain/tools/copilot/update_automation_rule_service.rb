class Captain::Tools::Copilot::UpdateAutomationRuleService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::AutomationRuleHelpers

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
    { "rule_id": 1, "actions": "[{"action_name": "execute_macro", "action_params": [macro_id]}]" }
  DESC

  param :rule_id, type: :integer, desc: 'ID of the automation rule to update', required: true
  param :name, type: 'string', desc: 'New name (optional)', required: false
  param :description, type: 'string', desc: 'New description (optional)', required: false
  param :event_name, type: 'string', desc: 'New event trigger (optional)', required: false
  param :conditions, type: 'string', desc: 'JSON string with new conditions (optional, replaces existing)', required: false
  param :actions, type: 'string', desc: 'JSON string with new actions (optional, replaces existing)', required: false
  param :active, type: 'boolean', desc: 'Whether the rule is active (optional)', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(rule_id:, name: nil, description: nil, event_name: nil, conditions: nil, actions: nil, active: nil)
    rule = @assistant.account.automation_rules.find_by(id: rule_id)
    return "Automation rule with ID #{rule_id} not found" if rule.blank?

    params = { name: name, description: description, event_name: event_name,
               conditions: conditions, actions: actions, active: active }
    updates = build_updates(params)
    return updates if updates.is_a?(String)
    return 'No updates provided.' if updates.empty?

    rule.update!(updates)

    {
      'content' => "Automation rule '#{rule.name}' updated successfully",
      'entities' => [format_rule_entity(rule)]
    }
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    true
  end

  private

  def build_updates(params)
    updates = build_simple_updates(params)

    error = process_event_name(updates, params[:event_name])
    return error if error

    error = process_conditions(updates, params[:conditions])
    return error if error

    error = process_actions(updates, params[:actions])
    return error if error

    updates
  end

  def build_simple_updates(params)
    updates = {}
    updates[:name] = params[:name] if params[:name].present?
    updates[:description] = params[:description] if params[:description].present?
    updates[:active] = params[:active] unless params[:active].nil?
    updates
  end

  def process_event_name(updates, event_name)
    return nil if event_name.blank?
    return "Invalid event_name. Valid: #{VALID_EVENTS.join(', ')}" unless VALID_EVENTS.include?(event_name)

    updates[:event_name] = event_name
    nil
  end

  def process_conditions(updates, conditions)
    return nil if conditions.blank?

    parsed_conditions = parse_json_param(conditions, 'conditions')
    return parsed_conditions if parsed_conditions.is_a?(String)

    normalized_conditions = normalize_conditions(parsed_conditions)
    return normalized_conditions if normalized_conditions.is_a?(String)

    updates[:conditions] = normalized_conditions
    nil
  end

  def process_actions(updates, actions)
    return nil if actions.blank?

    parsed_actions = parse_json_param(actions, 'actions')
    return parsed_actions if parsed_actions.is_a?(String)

    normalized_actions = normalize_actions(parsed_actions, resolve_params: true)
    return normalized_actions if normalized_actions.is_a?(String)

    updates[:actions] = normalized_actions
    nil
  end
end
