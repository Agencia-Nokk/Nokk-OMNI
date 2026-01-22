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
    tools = [Captain::Tools::SearchDocumentationService.new(@assistant, user: nil)]
    tools.concat(macro_tools)
    tools.concat(automation_tools)
    tools.concat(agent_tools)
    tools.concat(team_tools)
    tools.concat(settings_tools)
    tools.select(&:active?)
  end

  def macro_tools
    [
      Captain::Tools::Copilot::CreateMacroService,
      Captain::Tools::Copilot::ListMacrosService,
      Captain::Tools::Copilot::GetMacroService,
      Captain::Tools::Copilot::UpdateMacroService,
      Captain::Tools::Copilot::DeleteMacroService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def automation_tools
    [
      Captain::Tools::Copilot::CreateAutomationRuleService,
      Captain::Tools::Copilot::ListAutomationRulesService,
      Captain::Tools::Copilot::GetAutomationRuleService,
      Captain::Tools::Copilot::UpdateAutomationRuleService,
      Captain::Tools::Copilot::DeleteAutomationRuleService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def agent_tools
    [
      Captain::Tools::Copilot::CreateAgentService,
      Captain::Tools::Copilot::GetAgentService,
      Captain::Tools::Copilot::UpdateAgentService,
      Captain::Tools::Copilot::DeleteAgentService,
      Captain::Tools::Copilot::ListAgentsService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def team_tools
    [
      Captain::Tools::Copilot::CreateTeamService,
      Captain::Tools::Copilot::GetTeamService,
      Captain::Tools::Copilot::UpdateTeamService,
      Captain::Tools::Copilot::DeleteTeamService,
      Captain::Tools::Copilot::ListTeamsService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def settings_tools
    label_tools + canned_response_tools + custom_attribute_tools + custom_role_tools + sla_policy_tools + audit_log_tools
  end

  def label_tools
    [
      Captain::Tools::Copilot::CreateLabelService,
      Captain::Tools::Copilot::UpdateLabelService,
      Captain::Tools::Copilot::DeleteLabelService,
      Captain::Tools::Copilot::ListLabelsService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def canned_response_tools
    [
      Captain::Tools::Copilot::CreateCannedResponseService,
      Captain::Tools::Copilot::UpdateCannedResponseService,
      Captain::Tools::Copilot::DeleteCannedResponseService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def custom_attribute_tools
    [
      Captain::Tools::Copilot::CreateCustomAttributeService,
      Captain::Tools::Copilot::UpdateCustomAttributeService,
      Captain::Tools::Copilot::DeleteCustomAttributeService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def custom_role_tools
    [
      Captain::Tools::Copilot::CreateCustomRoleService,
      Captain::Tools::Copilot::GetCustomRoleService,
      Captain::Tools::Copilot::ListCustomRolesService,
      Captain::Tools::Copilot::UpdateCustomRoleService,
      Captain::Tools::Copilot::DeleteCustomRoleService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def sla_policy_tools
    [
      Captain::Tools::Copilot::CreateSlaPolicyService,
      Captain::Tools::Copilot::GetSlaPolicyService,
      Captain::Tools::Copilot::ListSlaPoliciesService,
      Captain::Tools::Copilot::UpdateSlaPolicyService,
      Captain::Tools::Copilot::DeleteSlaPolicyService
    ].map { |klass| klass.new(@assistant, user: nil) }
  end

  def audit_log_tools
    [
      Captain::Tools::Copilot::ListAuditLogsService,
      Captain::Tools::Copilot::GetAuditLogService
    ].map { |klass| klass.new(@assistant, user: nil) }
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
