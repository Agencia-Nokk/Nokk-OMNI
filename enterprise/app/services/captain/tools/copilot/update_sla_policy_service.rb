class Captain::Tools::Copilot::UpdateSlaPolicyService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SlaHelpers

  def self.name
    'update_sla_policy'
  end

  description <<~DESC
    Update an existing SLA policy.

    **Threshold values are in seconds:**
    - 3600 = 1 hour
    - 7200 = 2 hours
    - 86400 = 24 hours (1 day)

    Note: Set a threshold to 0 or null to remove it.
  DESC

  param :sla_policy_id, type: :number, desc: 'ID of the SLA policy to update'
  param :name, type: :string, desc: 'New name', required: false
  param :description, type: :string, desc: 'New description', required: false
  param :first_response_time_threshold, type: :number, desc: 'First response target (seconds)', required: false
  param :next_response_time_threshold, type: :number, desc: 'Next response target (seconds)', required: false
  param :resolution_time_threshold, type: :number, desc: 'Resolution target (seconds)', required: false
  param :only_during_business_hours, type: :boolean, desc: 'Only count business hours', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(sla_policy_id:, name: nil, description: nil, first_response_time_threshold: nil,
              next_response_time_threshold: nil, resolution_time_threshold: nil, only_during_business_hours: nil)
    sla = find_sla_policy(sla_policy_id: sla_policy_id)
    return 'SLA policy not found' unless sla

    params = { name: name, description: description, frt: first_response_time_threshold,
               nrt: next_response_time_threshold, rt: resolution_time_threshold, business_hours: only_during_business_hours }
    attrs = build_attrs(params)
    return 'No changes provided' if attrs.empty?

    update_sla_policy_record(sla, attrs)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    user_has_permission('administrator')
  end

  private

  def build_attrs(params)
    attrs = build_basic_attrs(params)
    add_threshold_attrs(attrs, params)
    attrs
  end

  def build_basic_attrs(params)
    attrs = {}
    attrs[:name] = params[:name].strip if params[:name].present?
    attrs[:description] = params[:description] if params[:description].present?
    attrs[:only_during_business_hours] = params[:business_hours] unless params[:business_hours].nil?
    attrs
  end

  def add_threshold_attrs(attrs, params)
    attrs[:first_response_time_threshold] = params[:frt] unless params[:frt].nil?
    attrs[:next_response_time_threshold] = params[:nrt] unless params[:nrt].nil?
    attrs[:resolution_time_threshold] = params[:rt] unless params[:rt].nil?
  end

  def update_sla_policy_record(sla, attrs)
    sla.update!(attrs)

    {
      'content' => "SLA policy '#{sla.name}' updated successfully",
      'entities' => [format_sla_policy_entity(sla)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update SLA policy: #{e.message}"
  end
end
