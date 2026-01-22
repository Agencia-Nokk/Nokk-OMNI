# frozen_string_literal: true

module Captain::Tools::Concerns::AutomationRuleResolvers
  extend ActiveSupport::Concern

  private

  def resolve_action_params(action_name, params)
    case action_name
    when 'assign_agent'
      resolve_agent_param(params)
    when 'assign_team', 'send_email_to_team'
      resolve_team_param(params)
    else
      Array(params)
    end
  end

  def resolve_agent_param(params)
    return Array(params) if params.blank?

    param = params.first
    return [param] if param.is_a?(Integer) || param.to_s.match?(/^\d+$/)

    agent = account_for_validation.users.find_by(
      'LOWER(name) = ? OR LOWER(email) = ?',
      param.to_s.downcase,
      param.to_s.downcase
    )
    return "Error: Agent '#{param}' not found. Use list_agents to see available agents." if agent.blank?

    [agent.id]
  end

  def resolve_team_param(params)
    return Array(params) if params.blank?

    param = params.first
    return [param.to_i] if param.is_a?(Integer) || param.to_s.match?(/^\d+$/)

    team = account_for_validation.teams.find_by('LOWER(name) = ?', param.to_s.downcase)
    return "Error: Team '#{param}' not found. Use list_teams to see available teams." if team.blank?

    [team.id]
  end
end
