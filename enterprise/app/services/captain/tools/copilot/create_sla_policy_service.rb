class Captain::Tools::Copilot::CreateSlaPolicyService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SlaHelpers

  def self.name
    'create_sla_policy'
  end

  description <<~DESC
    Create a new SLA (Service Level Agreement) policy. SLA policies define response time targets for conversations and help monitor team performance.

    **When to use:** Use this tool when you need to define response time commitments for customer support. For example: ensuring VIP customers get faster responses, tracking team performance, or meeting contractual obligations.

    **Complete Example:**
    To create an SLA policy for VIP customers with 1-hour first response and 24-hour resolution:
    {
      "name": "VIP Support",
      "description": "Premium SLA for VIP customers",
      "first_response_time_threshold": 3600,
      "next_response_time_threshold": 7200,
      "resolution_time_threshold": 86400,
      "only_during_business_hours": true
    }

    **Threshold Reference (in seconds):**
    - 1800 = 30 minutes
    - 3600 = 1 hour
    - 7200 = 2 hours
    - 14400 = 4 hours
    - 28800 = 8 hours (1 business day)
    - 86400 = 24 hours (1 day)
    - 172800 = 48 hours (2 days)

    **Common Use Cases:**
    1. VIP/Premium: first_response=3600 (1h), next_response=7200 (2h), resolution=86400 (24h)
    2. Standard Support: first_response=14400 (4h), next_response=28800 (8h), resolution=172800 (48h)
    3. Basic/Free Tier: first_response=86400 (24h), resolution=604800 (7 days)
    4. Urgent Issues: first_response=1800 (30min), next_response=3600 (1h), resolution=28800 (8h)

    **Business Hours:** Set only_during_business_hours=true to pause the SLA timer outside working hours.
    For more details: https://www.chatwoot.com/docs/product/features/sla
  DESC

  param :name, type: :string, desc: 'Name of the SLA policy'
  param :description, type: :string, desc: 'Description of the SLA policy', required: false
  param :first_response_time_threshold, type: :number, desc: 'First response target in seconds', required: false
  param :next_response_time_threshold, type: :number, desc: 'Next response target in seconds', required: false
  param :resolution_time_threshold, type: :number, desc: 'Resolution target in seconds', required: false
  param :only_during_business_hours, type: :boolean, desc: 'Only count business hours', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(name:, description: nil, first_response_time_threshold: nil,
              next_response_time_threshold: nil, resolution_time_threshold: nil, only_during_business_hours: nil)
    validation = validate_params(name)
    return validation if validation.is_a?(String) || validation.is_a?(Hash)

    params = { name: name, description: description, frt: first_response_time_threshold,
               nrt: next_response_time_threshold, rt: resolution_time_threshold, business_hours: only_during_business_hours }
    create_sla_policy_record(params)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    user_has_permission('administrator')
  end

  private

  def validate_params(name)
    return 'SLA policy name is required' if name.blank?

    existing = find_sla_policy(name: name)
    return existing_response(existing) if existing.present?

    true
  end

  def existing_response(sla)
    {
      'content' => "An SLA policy named '#{sla.name}' already exists (ID: #{sla.id}).",
      'entities' => [format_sla_policy_entity(sla)]
    }
  end

  def create_sla_policy_record(params)
    attrs = build_attrs(params)
    sla = @assistant.account.sla_policies.create!(attrs)

    {
      'content' => build_success_message(sla),
      'entities' => [format_sla_policy_entity(sla)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create SLA policy: #{e.message}"
  end

  def build_attrs(params)
    attrs = { name: params[:name].strip }
    attrs[:description] = params[:description] if params[:description].present?
    attrs[:first_response_time_threshold] = params[:frt] if params[:frt].present?
    attrs[:next_response_time_threshold] = params[:nrt] if params[:nrt].present?
    attrs[:resolution_time_threshold] = params[:rt] if params[:rt].present?
    attrs[:only_during_business_hours] = params[:business_hours] unless params[:business_hours].nil?
    attrs
  end

  def build_success_message(sla)
    msg = "SLA policy '#{sla.name}' created successfully."
    msg += " First response: #{format_threshold(sla.first_response_time_threshold)}." if sla.first_response_time_threshold
    msg += " Next response: #{format_threshold(sla.next_response_time_threshold)}." if sla.next_response_time_threshold
    msg += " Resolution: #{format_threshold(sla.resolution_time_threshold)}." if sla.resolution_time_threshold
    msg
  end
end
