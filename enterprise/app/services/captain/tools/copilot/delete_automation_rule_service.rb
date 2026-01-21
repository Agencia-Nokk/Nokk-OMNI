class Captain::Tools::Copilot::DeleteAutomationRuleService < Captain::Tools::BaseTool
  def self.name
    'delete_automation_rule'
  end

  description <<~DESC
    Delete an existing automation rule permanently.

    **Warning:** This action cannot be undone.

    First use list_automation_rules to find the rule ID you want to delete.
  DESC

  param :rule_id, type: :integer, desc: 'ID of the automation rule to delete', required: true

  def execute(rule_id:)
    rule = @assistant.account.automation_rules.find_by(id: rule_id)
    return "Automation rule with ID #{rule_id} not found" if rule.blank?

    rule_name = rule.name
    rule.destroy!

    Rails.logger.info { "#{self.class.name}: delete rule #{rule_id} (#{rule_name})" }

    "Automation rule '#{rule_name}' (ID: #{rule_id}) deleted successfully"
  end

  def active?
    true
  end
end
