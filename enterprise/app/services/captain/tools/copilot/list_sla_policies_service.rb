class Captain::Tools::Copilot::ListSlaPoliciesService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SlaHelpers

  def self.name
    'list_sla_policies'
  end

  description 'List all SLA policies available in the account'

  def execute
    sla_policies = @assistant.account.sla_policies
    return 'No SLA policies found in this account' if sla_policies.empty?

    {
      'content' => "Found #{sla_policies.count} SLA policy(ies):",
      'entities' => sla_policies.map { |sla| format_sla_policy_entity(sla) }
    }
  end

  def active?
    true
  end
end
