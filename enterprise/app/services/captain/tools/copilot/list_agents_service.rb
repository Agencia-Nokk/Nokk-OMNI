class Captain::Tools::Copilot::ListAgentsService < Captain::Tools::BaseTool
  def self.name
    'list_agents'
  end

  description <<~DESC
    List all agents (users) available in the account. Use this to find agent IDs
    when you need to assign conversations to specific agents in macros or automations.
  DESC

  def execute
    agents = @assistant.account.users.includes(:account_users)
                       .where(account_users: { role: [:agent, :administrator] })

    return 'No agents found in this account' if agents.empty?

    {
      'content' => "Found #{agents.count} agent(s):",
      'entities' => agents.map { |agent| format_agent_entity(agent) }
    }
  end

  def active?
    true
  end

  private

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
