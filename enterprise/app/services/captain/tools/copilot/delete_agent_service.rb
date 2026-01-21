class Captain::Tools::Copilot::DeleteAgentService < Captain::Tools::BaseTool
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
    agent = find_agent(agent_id)
    return 'Agent not found' unless agent

    account_user = agent.account_users.find { |au| au.account_id == @assistant.account.id }
    return 'Agent not found in this account' unless account_user

    # Prevent self-deletion
    if @user && agent.id == @user.id
      return 'You cannot remove yourself from the account'
    end

    agent_name = agent.available_name || agent.name
    agent_email = agent.email

    account_user.destroy!

    # Delete user record if they have no other accounts
    DeleteObjectJob.perform_later(agent) if agent.reload.account_users.blank?

    "Agent '#{agent_name}' (#{agent_email}) has been removed from the account"
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
end
