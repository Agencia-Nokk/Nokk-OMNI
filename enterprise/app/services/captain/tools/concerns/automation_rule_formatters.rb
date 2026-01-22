# frozen_string_literal: true

module Captain::Tools::Concerns::AutomationRuleFormatters
  extend ActiveSupport::Concern

  private

  def format_rule_entity(rule)
    {
      'type' => 'automation_rule',
      'id' => rule.id,
      'name' => rule.name,
      'event' => rule.event_name,
      'active' => rule.active
    }
  end

  def format_rule_details(rule)
    conditions_detail = format_conditions(rule.conditions)
    actions_detail = format_actions(rule.actions)

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

  def format_conditions(conditions)
    conditions.map.with_index(1) do |cond, idx|
      op = cond['query_operator'] ? " (#{cond['query_operator']})" : ''
      "  #{idx}. #{cond['attribute_key']} #{cond['filter_operator']} #{cond['values']}#{op}"
    end.join("\n")
  end

  def format_actions(actions)
    actions.map.with_index(1) do |action, idx|
      params = action['action_params']&.join(', ') || 'none'
      "  #{idx}. #{action['action_name']}: [#{params}]"
    end.join("\n")
  end
end
