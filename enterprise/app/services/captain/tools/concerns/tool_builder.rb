# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Captain::Tools::Concerns::ToolBuilder
  extend ActiveSupport::Concern

  private

  def macro_tools
    [
      Captain::Tools::Copilot::CreateMacroService,
      Captain::Tools::Copilot::ListMacrosService,
      Captain::Tools::Copilot::GetMacroService,
      Captain::Tools::Copilot::UpdateMacroService,
      Captain::Tools::Copilot::DeleteMacroService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def automation_tools
    [
      Captain::Tools::Copilot::CreateAutomationRuleService,
      Captain::Tools::Copilot::ListAutomationRulesService,
      Captain::Tools::Copilot::GetAutomationRuleService,
      Captain::Tools::Copilot::UpdateAutomationRuleService,
      Captain::Tools::Copilot::DeleteAutomationRuleService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def agent_tools
    [
      Captain::Tools::Copilot::ListAgentsService,
      Captain::Tools::Copilot::GetAgentService,
      Captain::Tools::Copilot::CreateAgentService,
      Captain::Tools::Copilot::UpdateAgentService,
      Captain::Tools::Copilot::DeleteAgentService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def team_tools
    [
      Captain::Tools::Copilot::ListTeamsService,
      Captain::Tools::Copilot::GetTeamService,
      Captain::Tools::Copilot::CreateTeamService,
      Captain::Tools::Copilot::UpdateTeamService,
      Captain::Tools::Copilot::DeleteTeamService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def label_tools
    [
      Captain::Tools::Copilot::ListLabelsService,
      Captain::Tools::Copilot::GetLabelService,
      Captain::Tools::Copilot::CreateLabelService,
      Captain::Tools::Copilot::UpdateLabelService,
      Captain::Tools::Copilot::DeleteLabelService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def canned_response_tools
    [
      Captain::Tools::Copilot::ListCannedResponsesService,
      Captain::Tools::Copilot::GetCannedResponseService,
      Captain::Tools::Copilot::CreateCannedResponseService,
      Captain::Tools::Copilot::UpdateCannedResponseService,
      Captain::Tools::Copilot::DeleteCannedResponseService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def custom_attribute_tools
    [
      Captain::Tools::Copilot::ListCustomAttributesService,
      Captain::Tools::Copilot::GetCustomAttributeService,
      Captain::Tools::Copilot::CreateCustomAttributeService,
      Captain::Tools::Copilot::UpdateCustomAttributeService,
      Captain::Tools::Copilot::DeleteCustomAttributeService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def custom_role_tools
    [
      Captain::Tools::Copilot::ListCustomRolesService,
      Captain::Tools::Copilot::GetCustomRoleService,
      Captain::Tools::Copilot::CreateCustomRoleService,
      Captain::Tools::Copilot::UpdateCustomRoleService,
      Captain::Tools::Copilot::DeleteCustomRoleService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def sla_policy_tools
    [
      Captain::Tools::Copilot::ListSlaPoliciesService,
      Captain::Tools::Copilot::GetSlaPolicyService,
      Captain::Tools::Copilot::CreateSlaPolicyService,
      Captain::Tools::Copilot::UpdateSlaPolicyService,
      Captain::Tools::Copilot::DeleteSlaPolicyService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def audit_log_tools
    [
      Captain::Tools::Copilot::ListAuditLogsService,
      Captain::Tools::Copilot::GetAuditLogService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  def custom_tool_tools
    [
      Captain::Tools::Copilot::SearchApiDocumentationService,
      Captain::Tools::Copilot::ReadApiDocumentationService,
      Captain::Tools::Copilot::AnalyzeApiSpecService,
      Captain::Tools::Copilot::ListCustomToolsService,
      Captain::Tools::Copilot::GetCustomToolService,
      Captain::Tools::Copilot::CreateCustomToolService,
      Captain::Tools::Copilot::UpdateCustomToolService,
      Captain::Tools::Copilot::DeleteCustomToolService
    ].map { |klass| klass.new(@assistant, user: tool_user) }
  end

  # Override in subclass to provide correct user
  def tool_user
    nil
  end
end
# rubocop:enable Metrics/ModuleLength
