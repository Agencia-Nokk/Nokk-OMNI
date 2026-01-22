class Captain::Tools::Copilot::CreateAgentBotService < Captain::Tools::BaseTool
  def self.name
    'create_agent_bot'
  end

  description <<~DESC
    Create a new agent bot in the account. Agent bots are automated assistants that handle conversations via webhooks or built-in AI capabilities.

    **When to use:** Use this tool when you need to create an automated bot to handle conversations. For example: welcome bots, FAQ bots, lead qualification bots, or custom integrations with external systems.

    **Complete Example:**
    To create a welcome bot that greets customers:
    {
      "name": "Welcome Bot",
      "description": "Greets new customers and collects initial information",
      "outgoing_url": "https://api.example.com/webhook/chatwoot"
    }

    **Bot Types:**
    - Webhook Bot: Sends events to your URL and receives responses (requires outgoing_url)
    - Captain Bot: Uses built-in AI (configure separately after creation)

    **Webhook Events Received:**
    - conversation_created: New conversation started
    - conversation_status_changed: Status changed (open/resolved/pending)
    - message_created: New message received
    - message_updated: Message was edited

    **Common Use Cases:**
    1. Welcome Bot: Greet customers and collect initial info
    2. FAQ Bot: Answer common questions automatically
    3. Lead Qualifier: Collect contact info before routing to agent
    4. After-Hours Bot: Handle conversations outside business hours
    5. Integration Bot: Connect to external CRM/ticketing systems

    **Note:** After creating the bot, connect it to inboxes in Settings > Inboxes > Select inbox > Agent Bot.
    For webhook integration: https://www.chatwoot.com/docs/product/features/agent-bots
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
