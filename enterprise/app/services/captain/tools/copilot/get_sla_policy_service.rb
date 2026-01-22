class Captain::Tools::Copilot::GetSlaPolicyService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SlaHelpers

  def self.name
    'get_sla_policy'
  end

  description 'Get full details of a specific SLA policy by ID or name'

  param :sla_policy_id, type: :number, desc: 'ID of the SLA policy', required: false
  param :name, type: :string, desc: 'Name of the SLA policy', required: false

  def execute(sla_policy_id: nil, name: nil)
    return 'Please provide either sla_policy_id or name' if sla_policy_id.blank? && name.blank?

    sla = find_sla_policy(sla_policy_id: sla_policy_id, name: name)
    return 'SLA policy not found' unless sla

    {
      'content' => build_details(sla),
      'entities' => [format_sla_policy_entity(sla)]
    }
  end

  def active?
    true
  end

  private

  def build_details(sla)
    <<~DETAILS.strip
      **SLA Policy:** #{sla.name}
      **Description:** #{sla.description || 'None'}
      **First Response Time:** #{format_threshold(sla.first_response_time_threshold)}
      **Next Response Time:** #{format_threshold(sla.next_response_time_threshold)}
      **Resolution Time:** #{format_threshold(sla.resolution_time_threshold)}
      **Business Hours Only:** #{sla.only_during_business_hours ? 'Yes' : 'No'}
      **Conversations:** #{sla.conversations.count}
    DETAILS
  end
end
