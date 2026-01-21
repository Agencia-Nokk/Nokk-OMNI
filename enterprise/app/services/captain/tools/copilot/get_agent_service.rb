class Captain::Tools::Copilot::GetAgentService < Captain::Tools::BaseTool
  def self.name
    'get_agent'
  end

  description 'Get details of a specific agent by ID, name, or email'

  param :agent_id, type: :number, desc: 'ID of the agent', required: false
  param :name, type: :string, desc: 'Name of the agent', required: false
  param :email, type: :string, desc: 'Email of the agent', required: false

  def execute(agent_id: nil, name: nil, email: nil)
    agent = find_agent(agent_id, name, email)
    return 'Agent not found' unless agent

    account_user = agent.account_users.find { |au| au.account_id == @assistant.account.id }

    {
      'content' => build_agent_details(agent, account_user),
      'entities' => [format_agent_entity(agent, account_user)]
    }
  end

  def active?
    true
  end

  private

  def find_agent(agent_id, name, email)
    agents = @assistant.account.users.includes(:account_users)
                       .where(account_users: { role: [:agent, :administrator] })

    if agent_id
      agents.find_by(id: agent_id)
    elsif email
      agents.find_by(email: email.downcase)
    elsif name
      agents.where('LOWER(name) LIKE ? OR LOWER(display_name) LIKE ?', "%#{name.downcase}%", "%#{name.downcase}%").first
    end
  end

  def build_agent_details(agent, account_user)
    <<~DETAILS.strip
      Agent details:

      **Name:** #{agent.available_name || agent.name}
      **Email:** #{agent.email}
      **Role:** #{account_user&.role&.capitalize || 'N/A'}
      **Availability:** #{account_user&.availability&.capitalize || 'N/A'}
      **Auto Offline:** #{account_user&.auto_offline ? 'Yes' : 'No'}
    DETAILS
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
