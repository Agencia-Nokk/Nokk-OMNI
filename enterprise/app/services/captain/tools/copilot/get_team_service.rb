class Captain::Tools::Copilot::GetTeamService < Captain::Tools::BaseTool
  def self.name
    'get_team'
  end

  description 'Get details of a specific team by ID or name, including its members'

  param :team_id, type: :number, desc: 'ID of the team', required: false
  param :name, type: :string, desc: 'Name of the team', required: false

  def execute(team_id: nil, name: nil)
    team = find_team(team_id, name)
    return 'Team not found' unless team

    {
      'content' => build_team_details(team),
      'entities' => [format_team_entity(team)]
    }
  end

  def active?
    true
  end

  private

  def find_team(team_id, name)
    if team_id
      @assistant.account.teams.find_by(id: team_id)
    elsif name
      @assistant.account.teams.find_by(name: name.downcase)
    end
  end

  def build_team_details(team)
    members_list = team.members.map { |m| "  - #{m.available_name || m.name} (#{m.email})" }.join("\n")
    members_section = team.members.any? ? "\n**Members:**\n#{members_list}" : "\n**Members:** None"

    <<~DETAILS.strip
      Team details:

      **Name:** #{team.name}
      **Description:** #{team.description || 'N/A'}
      **Auto-assign:** #{team.allow_auto_assign ? 'Enabled' : 'Disabled'}
      **Members count:** #{team.members.count}#{members_section}
    DETAILS
  end

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
