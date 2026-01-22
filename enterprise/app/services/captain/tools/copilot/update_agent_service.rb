class Captain::Tools::Copilot::UpdateAgentService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::AgentHelpers

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
    result = find_and_validate_agent(agent_id)
    return result if result.is_a?(String)

    agent, account_user = result
    changes = build_changes(name, role, availability, auto_offline)
    return changes if changes.is_a?(String)

    apply_changes(agent, account_user, changes)
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def find_and_validate_agent(agent_id)
    agent = find_agent(agent_id)
    return 'Agent not found' unless agent

    account_user = find_account_user(agent)
    return 'Agent not found in this account' unless account_user

    [agent, account_user]
  end

  def build_changes(name, role, availability, auto_offline)
    user_attrs = build_user_attrs(name)
    account_user_attrs = build_account_user_attrs(role, availability, auto_offline)
    return account_user_attrs if account_user_attrs.is_a?(String)

    return 'No changes provided' if user_attrs.empty? && account_user_attrs.empty?

    { user: user_attrs, account_user: account_user_attrs }
  end

  def build_user_attrs(name)
    attrs = {}
    attrs[:name] = name.strip if name.present?
    attrs
  end

  def build_account_user_attrs(role, availability, auto_offline)
    attrs = {}
    return add_role_attr(attrs, role, availability, auto_offline) if role.present?

    add_availability_and_auto_offline(attrs, availability, auto_offline)
  end

  def add_role_attr(attrs, role, availability, auto_offline)
    validated_role = validate_role(role)
    return 'Invalid role. Must be "agent" or "administrator"' unless validated_role

    attrs[:role] = validated_role
    add_availability_and_auto_offline(attrs, availability, auto_offline)
  end

  def add_availability_and_auto_offline(attrs, availability, auto_offline)
    if availability.present?
      validated = validate_availability(availability)
      return 'Invalid availability. Must be "online", "offline", or "busy"' unless validated

      attrs[:availability] = validated
    end

    attrs[:auto_offline] = auto_offline unless auto_offline.nil?
    attrs
  end

  def apply_changes(agent, account_user, changes)
    agent.update!(changes[:user]) if changes[:user].present?
    account_user.update!(changes[:account_user]) if changes[:account_user].present?

    {
      'content' => "Agent '#{agent.reload.available_name || agent.name}' updated successfully",
      'entities' => [format_agent_entity(agent.reload)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update agent: #{e.message}"
  end
end
