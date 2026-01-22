class Captain::Tools::Copilot::DeleteSlaPolicyService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SlaHelpers

  def self.name
    'delete_sla_policy'
  end

  description <<~DESC
    Delete an SLA policy from the account.
    Note: Conversations with this SLA will have their sla_policy set to null.
  DESC

  param :sla_policy_id, type: :number, desc: 'ID of the SLA policy to delete'

  def execute(sla_policy_id:)
    sla = find_sla_policy(sla_policy_id: sla_policy_id)
    return 'SLA policy not found' unless sla

    delete_sla(sla)
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def delete_sla(sla)
    name = sla.name
    affected_conversations = sla.conversations.count
    DeleteObjectJob.perform_later(sla)

    msg = "SLA policy '#{name}' deletion scheduled"
    msg += ". #{affected_conversations} conversation(s) will have their SLA removed." if affected_conversations.positive?
    msg
  end
end
