class Captain::Tools::Copilot::ListTeamsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TeamHelpers

  def self.name
    'list_teams'
  end

  description <<~DESC
    List all teams available in the account. Use this to find team IDs
    when you need to assign conversations to teams in macros or automations.
  DESC

  def execute
    teams = @assistant.account.teams.includes(:members)

    return 'No teams found in this account' if teams.empty?

    {
      'content' => "Found #{teams.count} team(s):",
      'entities' => teams.map { |team| format_team_entity(team) }
    }
  end

  def active?
    true
  end
end
