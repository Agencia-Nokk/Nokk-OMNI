class Captain::Tools::Copilot::ListAgentBotsService < Captain::Tools::BaseTool
  def self.name
    'list_agent_bots'
  end

  description <<~DESC
    List all agent bots available in the account. Agent bots are automated assistants
    that can handle conversations via webhooks.
  DESC

  def execute
    agent_bots = AgentBot.accessible_to(@assistant.account)

    return 'No agent bots found in this account' if agent_bots.empty?

    {
      'content' => "Found #{agent_bots.count} agent bot(s):",
      'entities' => agent_bots.map { |bot| format_bot_entity(bot) }
    }
  end

  def active?
    true
  end

  private

  def format_bot_entity(bot)
    {
      'type' => 'agent_bot',
      'id' => bot.id,
      'name' => bot.name,
      'description' => bot.description,
      'bot_type' => bot.bot_type,
      'outgoing_url' => bot.outgoing_url,
      'system_bot' => bot.system_bot?
    }
  end
end
