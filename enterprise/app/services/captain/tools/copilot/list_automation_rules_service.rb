class Captain::Tools::Copilot::ListAutomationRulesService < Captain::Tools::BaseTool
  def self.name
    'list_automation_rules'
  end

  description <<~DESC
    List available automation rules in the account. Returns rule ID, name, event, status, and summary.
    Use this to find automation rules before getting details or updating them.
  DESC

  param :name, type: :string, desc: 'Filter by name (partial match)', required: false
  param :active, type: :boolean, desc: 'Filter by active status', required: false

  def execute(name: nil, active: nil)
    rules = @assistant.account.automation_rules
    rules = rules.where('LOWER(name) ILIKE ?', "%#{name.downcase}%") if name.present?
    rules = rules.where(active: active) unless active.nil?
    rules = rules.limit(50).order(:name)

    return { 'content' => 'No automation rules found', 'entities' => [] } unless rules.exists?

    {
      'content' => "Found #{rules.count} automation rule(s):",
      'entities' => rules.map { |r| format_rule_entity(r) }
    }
  end

  def active?
    true
  end

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
end
