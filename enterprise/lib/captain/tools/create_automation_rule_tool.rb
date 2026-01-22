require_relative 'automation_rule_description'

class Captain::Tools::CreateAutomationRuleTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::AutomationRuleHelpers

  description Captain::Tools::AutomationRuleDescription::TOOL_DESCRIPTION

  param :name, type: 'string', desc: 'A descriptive name for the automation rule'
  param :description, type: 'string', desc: 'Optional description explaining what the rule does', required: false
  param :event_name, type: 'string',
                     desc: 'The event that triggers the rule: conversation_created, conversation_updated, ' \
                           'conversation_opened, conversation_resolved, or message_created'
  param :conditions, type: 'string', desc: Captain::Tools::AutomationRuleDescription::CONDITIONS_PARAM_DESC
  param :actions, type: 'string', desc: Captain::Tools::AutomationRuleDescription::ACTIONS_PARAM_DESC
  param :active, type: 'boolean', desc: 'Whether the rule is active (default: true)', required: false

  # rubocop:disable Metrics/ParameterLists
  def perform(_tool_context, name:, event_name:, conditions:, actions:, description: nil, active: true)
    error = validate_basic_params(name, event_name)
    return error if error

    existing_rule = find_existing_rule(name)
    return "Rule '#{existing_rule.name}' already exists (ID: #{existing_rule.id}). Use update_automation_rule to modify it." if existing_rule.present?

    result = process_and_create_rule(
      { name: name, event_name: event_name, description: description, active: active },
      conditions, actions
    )
    return result if result.is_a?(String)

    result
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def validate_basic_params(name, event_name)
    return 'Rule name is required' if name.blank?
    return "Invalid event_name. Valid events: #{VALID_EVENTS.join(', ')}" unless VALID_EVENTS.include?(event_name)

    nil
  end

  def process_and_create_rule(params, conditions, actions)
    normalized = process_conditions_and_actions(conditions, actions)
    return normalized if normalized.is_a?(String)

    rule = create_automation_rule(params, normalized[:conditions], normalized[:actions])
    log_creation(rule, params, normalized)

    "Automation rule created successfully!\n\n#{format_rule_details(rule)}"
  end

  def process_conditions_and_actions(conditions, actions)
    parsed_conditions = parse_json_param(conditions, 'conditions')
    return parsed_conditions if parsed_conditions.is_a?(String)

    parsed_actions = parse_json_param(actions, 'actions')
    return parsed_actions if parsed_actions.is_a?(String)

    normalized_conditions = normalize_conditions(parsed_conditions)
    return normalized_conditions if normalized_conditions.is_a?(String)

    normalized_actions = normalize_actions(parsed_actions)
    return normalized_actions if normalized_actions.is_a?(String)

    { conditions: normalized_conditions, actions: normalized_actions }
  end

  def find_existing_rule(name)
    @assistant.account.automation_rules.find_by('LOWER(name) = ?', name.downcase)
  end

  def create_automation_rule(params, conditions, actions)
    @assistant.account.automation_rules.create!(
      name: params[:name],
      description: params[:description],
      event_name: params[:event_name],
      conditions: conditions,
      actions: actions,
      active: params[:active]
    )
  end

  def log_creation(rule, params, normalized)
    log_tool_usage('create_automation_rule', {
                     rule_id: rule.id,
                     name: params[:name],
                     event_name: params[:event_name],
                     conditions_count: normalized[:conditions].size,
                     actions_count: normalized[:actions].size
                   })
  end
end
