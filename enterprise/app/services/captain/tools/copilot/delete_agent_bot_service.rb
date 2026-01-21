class Captain::Tools::Copilot::DeleteAgentBotService < Captain::Tools::BaseTool
  def self.name
    'delete_agent_bot'
  end

  description <<~DESC
    Delete an agent bot from the account.

    **Warning:** This will remove the bot from all connected inboxes and cannot be undone.
    Conversations that were handled by this bot will remain but the bot will no longer be available.

    **Note:** You can only delete bots that belong to your account (not system bots).
  DESC

  param :agent_bot_id, type: :number, desc: 'ID of the agent bot to delete'

  def execute(agent_bot_id:)
    bot = @assistant.account.agent_bots.find_by(id: agent_bot_id)
    return 'Agent bot not found or is a system bot that cannot be deleted' unless bot

    bot_name = bot.name
    bot.destroy!

    "Agent bot '#{bot_name}' deleted successfully"
  end

  def active?
    user_has_permission('administrator')
  end
end
