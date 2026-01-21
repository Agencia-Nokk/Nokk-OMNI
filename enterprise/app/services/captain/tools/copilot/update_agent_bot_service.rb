class Captain::Tools::Copilot::UpdateAgentBotService < Captain::Tools::BaseTool
  def self.name
    'update_agent_bot'
  end

  description <<~DESC
    Update an existing agent bot. You can update name, description, or webhook URL.

    **Note:** You can only update bots that belong to your account (not system bots).
  DESC

  param :agent_bot_id, type: :number, desc: 'ID of the agent bot to update'
  param :name, type: :string, desc: 'New name for the bot', required: false
  param :description, type: :string, desc: 'New description', required: false
  param :outgoing_url, type: :string, desc: 'New webhook URL', required: false

  def execute(agent_bot_id:, name: nil, description: nil, outgoing_url: nil)
    bot = @assistant.account.agent_bots.find_by(id: agent_bot_id)
    return 'Agent bot not found or is a system bot that cannot be modified' unless bot

    attrs = {}
    attrs[:name] = name.strip if name.present?
    attrs[:description] = description if description.present?
    attrs[:outgoing_url] = outgoing_url if outgoing_url.present?

    return 'No changes provided' if attrs.empty?

    bot.update!(attrs)

    {
      'content' => "Agent bot '#{bot.reload.name}' updated successfully",
      'entities' => [format_bot_entity(bot)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update agent bot: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def format_bot_entity(bot)
    {
      'type' => 'agent_bot',
      'id' => bot.id,
      'name' => bot.name,
      'description' => bot.description,
      'bot_type' => bot.bot_type,
      'outgoing_url' => bot.outgoing_url
    }
  end
end
