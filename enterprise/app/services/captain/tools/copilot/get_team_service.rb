class Captain::Tools::Copilot::GetTeamService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TeamHelpers

  def self.name
    'get_team'
  end

  description 'Get details of a specific team by ID or name, including its members'

  param :team_id, type: :number, desc: 'ID of the team', required: false
  param :name, type: :string, desc: 'Name of the team', required: false

  def execute(team_id: nil, name: nil)
    team = find_team_by_id_or_name(team_id: team_id, name: name)
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
end
