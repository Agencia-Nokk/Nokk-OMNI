class Captain::Copilot::ChatService < Llm::BaseAiService
  include Captain::ChatHelper
  include Captain::Tools::Concerns::ToolBuilder

  attr_reader :assistant, :account, :user, :copilot_thread, :previous_history, :messages

  def initialize(assistant, config)
    super()

    @assistant = assistant
    @account = assistant.account
    @user = nil
    @copilot_thread = nil
    @previous_history = []
    @conversation_id = config[:conversation_id]

    setup_user(config)
    setup_message_history(config)
    @tools = build_tools
    @messages = build_messages(config)
  end

  def generate_response(input)
    @messages << { role: 'user', content: input } if input.present?
    response = request_chat_completion

    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Incrementing response usage for account #{@account.id}"
    )
    @account.increment_response_usage

    response
  end

  private

  def setup_user(config)
    @user = @account.users.find_by(id: config[:user_id]) if config[:user_id].present?
  end

  def build_messages(config)
    messages= [system_message]
    messages << account_id_context
    messages += @previous_history if @previous_history.present?
    messages += current_viewing_history(config[:conversation_id]) if config[:conversation_id].present?
    messages
  end

  def setup_message_history(config)
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Previous History: #{config[:previous_history]&.length || 0}, Language: #{config[:language]}"
    )

    @copilot_thread = @account.copilot_threads.find_by(id: config[:copilot_thread_id]) if config[:copilot_thread_id].present?
    @previous_history = if @copilot_thread.present?
                          @copilot_thread.previous_history
                        else
                          config[:previous_history].presence || []
                        end
  end

  def build_tools
    tools = [Captain::Tools::SearchDocumentationService.new(@assistant, user: @user)]
    tools.concat(search_tools)
    tools.concat(macro_tools)
    tools.concat(automation_tools)
    tools.concat(agent_tools)
    tools.concat(team_tools)
    tools.concat(settings_tools)
    tools.select(&:active?)
  end

  def search_tools
    [
      Captain::Tools::Copilot::GetConversationService,
      Captain::Tools::Copilot::SearchConversationsService,
      Captain::Tools::Copilot::GetContactService,
      Captain::Tools::Copilot::GetArticleService,
      Captain::Tools::Copilot::SearchArticlesService,
      Captain::Tools::Copilot::SearchContactsService,
      Captain::Tools::Copilot::SearchLinearIssuesService
    ].map { |klass| klass.new(@assistant, user: @user) }
  end

  def settings_tools
    label_tools + canned_response_tools + agent_bot_tools + custom_attribute_tools + custom_role_tools + sla_policy_tools +
      audit_log_tools + custom_tool_tools
  end

  def agent_bot_tools
    [
      Captain::Tools::Copilot::ListAgentBotsService,
      Captain::Tools::Copilot::GetAgentBotService,
      Captain::Tools::Copilot::CreateAgentBotService,
      Captain::Tools::Copilot::UpdateAgentBotService,
      Captain::Tools::Copilot::DeleteAgentBotService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def tool_user
    @user
  end

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.copilot_response_generator(
        @assistant.config['product_name'],
        tools_summary,
        @assistant.config
      )
    }
  end

  def tools_summary
    @tools.map { |tool| "- #{tool.class.name}: #{tool.class.description}" }.join("\n")
  end

  def account_id_context
    {
      role: 'system',
      content: "The current account id is #{@account.id}. The account is using #{@account.locale_english_name} as the language."
    }
  end

  def current_viewing_history(conversation_id)
    conversation = @account.conversations.find_by(display_id: conversation_id)
    return [] unless conversation

    Rails.logger.info("#{self.class.name} Assistant: #{@assistant.id}, Setting viewing history for conversation_id=#{conversation_id}")

    [{
      role: 'system',
      content: <<~HISTORY.strip
        You are currently viewing the following conversation:
        #{conversation.to_llm_text(include_private_messages: true, include_contact_details: true)}
      HISTORY
    }]
  end

  def persist_message(message, message_type = 'assistant')
    return if @copilot_thread.blank?

    @copilot_thread.copilot_messages.create!(
      message: message,
      message_type: message_type
    )
  end

  def feature_name
    'copilot'
  end
end
