require_relative '../../../../../lib/captain/tools/automation_rule_description'

class Captain::Tools::Copilot::CreateAutomationRuleService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::AutomationRuleHelpers

  def self.name
    'create_automation_rule'
  end

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
  def execute(name:, event_name:, conditions:, actions:, description: nil, active: true)
    error = validate_basic_params(name, event_name)
    return error if error

    existing_rule = find_existing_rule(name)
    return existing_rule_response(existing_rule) if existing_rule.present?

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
    log_rule_creation(rule, params, normalized)

    success_response(rule)
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

  def success_response(rule)
    {
      'content' => "Automation rule created successfully!\n\n#{format_rule_details(rule)}",
      'entities' => [format_rule_entity(rule)]
    }
  end

  def active?
    true
  end

  def find_existing_rule(name)
    @assistant.account.automation_rules.find_by('LOWER(name) = ?', name.downcase)
  end

  def existing_rule_response(rule)
    {
      'content' => "An automation rule named '#{rule.name}' already exists (ID: #{rule.id}). " \
                   'Would you like to update the existing rule using the update_automation_rule tool, or create a new one with a different name?',
      'entities' => [format_rule_entity(rule)]
    }
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

  def log_rule_creation(rule, params, normalized)
    Rails.logger.info do
      details = { rule_id: rule.id, name: params[:name], event_name: params[:event_name],
                  conditions_count: normalized[:conditions].size, actions_count: normalized[:actions].size }
      "#{self.class.name}: create_automation_rule for assistant #{@assistant&.id} - #{details.inspect}"
    end
  end
end
