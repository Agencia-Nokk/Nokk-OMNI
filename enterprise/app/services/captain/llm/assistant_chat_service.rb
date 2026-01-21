class Captain::Llm::AssistantChatService < Llm::BaseAiService
  include Captain::ChatHelper

  def initialize(assistant: nil, conversation_id: nil)
    super()

    @assistant = assistant
    @conversation_id = conversation_id

    @messages = [system_message]
    @response = ''
    @tools = build_tools
  end

  # additional_message: A single message (String) from the user that should be appended to the chat.
  #                    It can be an empty String or nil when you only want to supply historical messages.
  # message_history:   An Array of already formatted messages that provide the previous context.
  # role:              The role for the additional_message (defaults to `user`).
  #
  # NOTE: Parameters are provided as keyword arguments to improve clarity and avoid relying on
  # positional ordering.
  def generate_response(additional_message: nil, message_history: [], role: 'user')
    @messages += message_history
    @messages << { role: role, content: additional_message } if additional_message.present?
    request_chat_completion
  end

  private

  def build_tools
    tools = []
    tools << Captain::Tools::SearchDocumentationService.new(@assistant, user: nil)

    # Macro tools
    tools << Captain::Tools::Copilot::CreateMacroService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::ListMacrosService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::GetMacroService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::UpdateMacroService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::DeleteMacroService.new(@assistant, user: nil)

    # Automation tools
    tools << Captain::Tools::Copilot::CreateAutomationRuleService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::ListAutomationRulesService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::GetAutomationRuleService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::UpdateAutomationRuleService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::DeleteAutomationRuleService.new(@assistant, user: nil)

    # Helper tools for entity references
    tools << Captain::Tools::Copilot::ListAgentsService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::ListTeamsService.new(@assistant, user: nil)
    tools << Captain::Tools::Copilot::ListLabelsService.new(@assistant, user: nil)

    tools.select(&:active?)
  end

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.assistant_response_generator(@assistant.name, @assistant.config['product_name'], @assistant.config)
    }
  end

  def persist_message(message, message_type = 'assistant')
    # No need to implement
  end

  def feature_name
    'assistant'
  end
end
