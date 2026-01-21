class Captain::Tools::Copilot::UpdateAgentService < Captain::Tools::BaseTool
  def self.name
    'update_agent'
  end

  description <<~DESC
    Update an existing agent's information. You can update their name, role, availability, or auto-offline setting.

    **Parameters:**
    - agent_id: Required. ID of the agent to update.
    - name: Optional. New name for the agent.
    - role: Optional. New role: 'agent' or 'administrator'.
    - availability: Optional. New availability status: 'online', 'offline', or 'busy'.
    - auto_offline: Optional. Whether to automatically set agent offline when inactive (true/false).
  DESC

  param :agent_id, type: :number, desc: 'ID of the agent to update'
  param :name, type: :string, desc: 'New name for the agent', required: false
  param :role, type: :string, desc: 'New role: "agent" or "administrator"', required: false
  param :availability, type: :string, desc: 'Availability: "online", "offline", or "busy"', required: false
  param :auto_offline, type: :boolean, desc: 'Auto offline when inactive', required: false

  def execute(agent_id:, name: nil, role: nil, availability: nil, auto_offline: nil)
    agent = find_agent(agent_id)
    return 'Agent not found' unless agent

    account_user = agent.account_users.find { |au| au.account_id == @assistant.account.id }
    return 'Agent not found in this account' unless account_user

    user_attrs = {}
    account_user_attrs = {}

    user_attrs[:name] = name.strip if name.present?

    if role.present?
      validated_role = validate_role(role)
      return 'Invalid role. Must be "agent" or "administrator"' unless validated_role

      account_user_attrs[:role] = validated_role
    end

    if availability.present?
      validated_availability = validate_availability(availability)
      return 'Invalid availability. Must be "online", "offline", or "busy"' unless validated_availability

      account_user_attrs[:availability] = validated_availability
    end

    account_user_attrs[:auto_offline] = auto_offline unless auto_offline.nil?

    return 'No changes provided' if user_attrs.empty? && account_user_attrs.empty?

    agent.update!(user_attrs) if user_attrs.present?
    account_user.update!(account_user_attrs) if account_user_attrs.present?

    {
      'content' => "Agent '#{agent.reload.available_name || agent.name}' updated successfully",
      'entities' => [format_agent_entity(agent.reload)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update agent: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def find_agent(agent_id)
    @assistant.account.users.includes(:account_users)
              .where(account_users: { role: [:agent, :administrator] })
              .find_by(id: agent_id)
  end

  def validate_role(role)
    role = role.to_s.downcase.strip
    return :agent if role == 'agent'
    return :administrator if %w[administrator admin].include?(role)

    nil
  end

  def validate_availability(availability)
    availability = availability.to_s.downcase.strip
    return :online if availability == 'online'
    return :offline if availability == 'offline'
    return :busy if availability == 'busy'

    nil
  end

  def format_agent_entity(agent)
    account_user = agent.account_users.find { |au| au.account_id == @assistant.account.id }
    {
      'type' => 'agent',
      'id' => agent.id,
      'name' => agent.available_name || agent.name,
      'email' => agent.email,
      'role' => account_user&.role,
      'availability' => account_user&.availability
    }
  end
end
