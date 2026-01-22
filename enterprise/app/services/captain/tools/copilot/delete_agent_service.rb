class Captain::Tools::Copilot::DeleteAgentService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::AgentHelpers

  def self.name
    'delete_agent'
  end

  description <<~DESC
    Remove an agent from the account. This will revoke their access to this account.

    **Warning:** This action cannot be undone. The agent will lose access to all conversations, contacts, and data in this account.

    **Note:** If the agent has no other accounts, their user record will also be deleted.
  DESC

  param :agent_id, type: :number, desc: 'ID of the agent to remove'

  def execute(agent_id:)
    result = find_and_validate_agent_for_deletion(agent_id)
    return result if result.is_a?(String)

    agent, account_user = result
    delete_agent(agent, account_user)
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def find_and_validate_agent_for_deletion(agent_id)
    agent = find_agent(agent_id)
    return 'Agent not found' unless agent

    account_user = find_account_user(agent)
    return 'Agent not found in this account' unless account_user
    return 'You cannot remove yourself from the account' if @user && agent.id == @user.id

    [agent, account_user]
  end

  def delete_agent(agent, account_user)
    agent_name = agent.available_name || agent.name
    agent_email = agent.email

    account_user.destroy!
    DeleteObjectJob.perform_later(agent) if agent.reload.account_users.blank?

    "Agent '#{agent_name}' (#{agent_email}) has been removed from the account"
  end
end
