class Captain::Copilot::ChatService < Llm::BaseAiService
  include Captain::ChatHelper

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
    tools = []

    tools << Captain::Tools::SearchDocumentationService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetConversationService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::SearchConversationsService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetContactService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetArticleService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::SearchArticlesService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::SearchContactsService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::SearchLinearIssuesService.new(@assistant, user: @user)
    # Macro tools
    tools << Captain::Tools::Copilot::CreateMacroService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::ListMacrosService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetMacroService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateMacroService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteMacroService.new(@assistant, user: @user)

    # Automation tools
    tools << Captain::Tools::Copilot::CreateAutomationRuleService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::ListAutomationRulesService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetAutomationRuleService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateAutomationRuleService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteAutomationRuleService.new(@assistant, user: @user)

    # Agent tools
    tools << Captain::Tools::Copilot::ListAgentsService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetAgentService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::CreateAgentService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateAgentService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteAgentService.new(@assistant, user: @user)

    # Team tools
    tools << Captain::Tools::Copilot::ListTeamsService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetTeamService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::CreateTeamService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateTeamService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteTeamService.new(@assistant, user: @user)

    # Label tools
    tools << Captain::Tools::Copilot::ListLabelsService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetLabelService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::CreateLabelService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateLabelService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteLabelService.new(@assistant, user: @user)

    # Canned Response tools
    tools << Captain::Tools::Copilot::ListCannedResponsesService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetCannedResponseService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::CreateCannedResponseService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateCannedResponseService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteCannedResponseService.new(@assistant, user: @user)

    # Agent Bot tools
    tools << Captain::Tools::Copilot::ListAgentBotsService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetAgentBotService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::CreateAgentBotService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateAgentBotService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteAgentBotService.new(@assistant, user: @user)

    # Custom Attribute tools
    tools << Captain::Tools::Copilot::ListCustomAttributesService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetCustomAttributeService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::CreateCustomAttributeService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateCustomAttributeService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteCustomAttributeService.new(@assistant, user: @user)

    # Custom Role tools
    tools << Captain::Tools::Copilot::ListCustomRolesService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::GetCustomRoleService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::CreateCustomRoleService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::UpdateCustomRoleService.new(@assistant, user: @user)
    tools << Captain::Tools::Copilot::DeleteCustomRoleService.new(@assistant, user: @user)

    tools.select(&:active?)
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
