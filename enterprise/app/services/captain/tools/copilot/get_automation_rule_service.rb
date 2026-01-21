class Captain::Tools::Copilot::GetAutomationRuleService < Captain::Tools::BaseTool
  def self.name
    'get_automation_rule'
  end

  description <<~DESC
    Get full details of a specific automation rule including all conditions and actions.
    Use this to see the complete configuration before updating.
  DESC

  param :rule_id, type: :integer, desc: 'ID of the automation rule to retrieve', required: true

  def execute(rule_id:)
    rule = @assistant.account.automation_rules.find_by(id: rule_id)
    return "Automation rule with ID #{rule_id} not found" if rule.blank?

    {
      'content' => format_rule_details(rule),
      'entities' => [format_rule_entity(rule)]
    }
  end

  def active?
    true
  end

  private

  def format_rule_details(rule)
    conditions_detail = rule.conditions.map.with_index(1) do |cond, idx|
      op = cond['query_operator'] ? " (#{cond['query_operator']})" : ''
      "  #{idx}. #{cond['attribute_key']} #{cond['filter_operator']} #{cond['values']}#{op}"
    end.join("\n")

    actions_detail = rule.actions.map.with_index(1) do |action, idx|
      params = action['action_params']&.join(', ') || 'none'
      "  #{idx}. #{action['action_name']}: [#{params}]"
    end.join("\n")

    <<~DETAILS.strip
      **Name:** #{rule.name}
      **Description:** #{rule.description || 'None'}
      **Event:** #{rule.event_name}
      **Active:** #{rule.active}
      **Conditions:**
      #{conditions_detail}
      **Actions:**
      #{actions_detail}
    DETAILS
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
end
