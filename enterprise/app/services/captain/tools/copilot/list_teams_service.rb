class Captain::Tools::Copilot::ListTeamsService < Captain::Tools::BaseTool
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

  private

  def format_team_entity(team)
    {
      'type' => 'team',
      'id' => team.id,
      'name' => team.name,
      'description' => team.description,
      'members_count' => team.members.count,
      'allow_auto_assign' => team.allow_auto_assign
    }
  end
end
