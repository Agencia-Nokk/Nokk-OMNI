class Captain::Tools::Copilot::GetAgentBotService < Captain::Tools::BaseTool
  def self.name
    'get_agent_bot'
  end

  description 'Get details of a specific agent bot by ID or name'

  param :agent_bot_id, type: :number, desc: 'ID of the agent bot', required: false
  param :name, type: :string, desc: 'Name of the agent bot', required: false

  def execute(agent_bot_id: nil, name: nil)
    bot = find_bot(agent_bot_id, name)
    return 'Agent bot not found' unless bot

    {
      'content' => build_bot_details(bot),
      'entities' => [format_bot_entity(bot)]
    }
  end

  def active?
    true
  end

  private

  def find_bot(agent_bot_id, name)
    bots = AgentBot.accessible_to(@assistant.account)

    if agent_bot_id
      bots.find_by(id: agent_bot_id)
    elsif name
      bots.where('LOWER(name) LIKE ?', "%#{name.downcase}%").first
    end
  end

  def build_bot_details(bot)
    inboxes_list = bot.inboxes.where(account_id: @assistant.account.id).pluck(:name).join(', ')
    inboxes_section = (inboxes_list.presence || 'None')

    <<~DETAILS.strip
      Agent bot details:

      **Name:** #{bot.name}
      **Description:** #{bot.description || 'N/A'}
      **Type:** #{bot.bot_type}
      **Outgoing URL:** #{bot.outgoing_url || 'N/A'}
      **System bot:** #{bot.system_bot? ? 'Yes' : 'No'}
      **Connected inboxes:** #{inboxes_section}
    DETAILS
  end

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
