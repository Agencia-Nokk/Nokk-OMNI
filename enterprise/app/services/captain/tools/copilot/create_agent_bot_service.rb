class Captain::Tools::Copilot::CreateAgentBotService < Captain::Tools::BaseTool
  def self.name
    'create_agent_bot'
  end

  description <<~DESC
    Create a new agent bot in the account. Agent bots are automated assistants that
    handle conversations via webhooks.

    **Parameters:**
    - name: Required. Name of the bot.
    - description: Optional. Description of what the bot does.
    - outgoing_url: Optional. Webhook URL where the bot will receive events.

    **Note:** After creating the bot, you can connect it to inboxes through the settings page.
  DESC

  param :name, type: :string, desc: 'Name of the agent bot'
  param :description, type: :string, desc: 'Description of the bot', required: false
  param :outgoing_url, type: :string, desc: 'Webhook URL for receiving events', required: false

  def execute(name:, description: nil, outgoing_url: nil)
    return 'Bot name is required' if name.blank?

    existing = @assistant.account.agent_bots.find_by('LOWER(name) = ?', name.downcase)
    if existing.present?
      return {
        'content' => "An agent bot with name '#{name}' already exists.",
        'entities' => [format_bot_entity(existing)]
      }
    end

    attrs = { name: name.strip }
    attrs[:description] = description if description.present?
    attrs[:outgoing_url] = outgoing_url if outgoing_url.present?

    bot = @assistant.account.agent_bots.create!(attrs)

    {
      'content' => "Agent bot '#{bot.name}' created successfully. You can now connect it to inboxes in the settings.",
      'entities' => [format_bot_entity(bot)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create agent bot: #{e.message}"
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
