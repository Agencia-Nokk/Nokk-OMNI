class Captain::Tools::Copilot::GetAgentService < Captain::Tools::BaseTool
  def self.name
    'get_agent'
  end

  description 'Get details of a specific agent by ID, name, or email'

  param :agent_id, type: :number, desc: 'ID of the agent', required: false
  param :name, type: :string, desc: 'Name of the agent', required: false
  param :email, type: :string, desc: 'Email of the agent', required: false

  def execute(agent_id: nil, name: nil, email: nil)
    agent = find_agent_by_criteria(agent_id, name, email)
    return 'Agent not found' unless agent

    build_response(agent)
  end

  def active?
    true
  end

  private

  def find_agent_by_criteria(agent_id, name, email)
    agents = account_agents_scope
    find_by_id_email_or_name(agents, agent_id, name, email)
  end

  def account_agents_scope
    @assistant.account.users.includes(:account_users)
              .where(account_users: { role: [:agent, :administrator] })
  end

  def find_by_id_email_or_name(agents, agent_id, name, email)
    return agents.find_by(id: agent_id) if agent_id
    return agents.find_by(email: email.downcase) if email
    return find_by_name(agents, name) if name
  end

  def find_by_name(agents, name)
    agents.where('LOWER(name) LIKE ? OR LOWER(display_name) LIKE ?', "%#{name.downcase}%", "%#{name.downcase}%").first
  end

  def build_response(agent)
    account_user = agent.account_users.find { |au| au.account_id == @assistant.account.id }

    {
      'content' => build_agent_details(agent, account_user),
      'entities' => [format_agent_entity(agent, account_user)]
    }
  end

  def build_agent_details(agent, account_user)
    <<~DETAILS.strip
      Agent details:

      **Name:** #{agent_name(agent)}
      **Email:** #{agent.email}
      **Role:** #{agent_role(account_user)}
      **Availability:** #{agent_availability(account_user)}
      **Auto Offline:** #{agent_auto_offline(account_user)}
    DETAILS
  end

  def agent_name(agent)
    agent.available_name || agent.name
  end

  def agent_role(account_user)
    account_user&.role&.capitalize || 'N/A'
  end

  def agent_availability(account_user)
    account_user&.availability&.capitalize || 'N/A'
  end

  def agent_auto_offline(account_user)
    account_user&.auto_offline ? 'Yes' : 'No'
  end

  def format_agent_entity(agent, account_user)
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
