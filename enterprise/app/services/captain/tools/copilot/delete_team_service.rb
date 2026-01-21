class Captain::Tools::Copilot::DeleteTeamService < Captain::Tools::BaseTool
  def self.name
    'delete_team'
  end

  description <<~DESC
    Delete a team from the account.

    **Warning:** This will remove the team and all its member associations.
    Conversations assigned to this team will have their team assignment cleared.
  DESC

  param :team_id, type: :number, desc: 'ID of the team to delete'

  def execute(team_id:)
    team = @assistant.account.teams.find_by(id: team_id)
    return 'Team not found' unless team

    team_name = team.name
    team.destroy!

    "Team '#{team_name}' deleted successfully"
  end

  def active?
    user_has_permission('administrator')
  end
end
