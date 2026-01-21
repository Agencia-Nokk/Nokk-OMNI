class Captain::Tools::Copilot::CreateTeamService < Captain::Tools::BaseTool
  def self.name
    'create_team'
  end

  description <<~DESC
    Create a new team in the account. Teams are used to group agents and route conversations.

    **Parameters:**
    - name: Required. Team name (will be converted to lowercase).
    - description: Optional. Description of the team's purpose.
    - allow_auto_assign: Optional. Enable auto-assignment of conversations (default: true).
    - member_ids: Optional. JSON array of agent IDs to add as members (e.g., "[1, 2, 3]").
  DESC

  param :name, type: :string, desc: 'Team name'
  param :description, type: :string, desc: 'Team description', required: false
  param :allow_auto_assign, type: :boolean, desc: 'Enable auto-assignment (default: true)', required: false
  param :member_ids, type: :string, desc: 'JSON array of agent IDs to add as members', required: false

  def execute(name:, description: nil, allow_auto_assign: nil, member_ids: nil)
    return 'Team name is required' if name.blank?

    existing = @assistant.account.teams.find_by(name: name.downcase)
    if existing.present?
      return {
        'content' => "A team with name '#{name}' already exists.",
        'entities' => [format_team_entity(existing)]
      }
    end

    attrs = { name: name.downcase.strip }
    attrs[:description] = description if description.present?
    attrs[:allow_auto_assign] = allow_auto_assign unless allow_auto_assign.nil?

    team = @assistant.account.teams.create!(attrs)

    # Add members if provided
    if member_ids.present?
      ids = parse_member_ids(member_ids)
      team.add_members(ids) if ids.any?
    end

    {
      'content' => "Team '#{team.name}' created successfully with #{team.members.count} member(s).",
      'entities' => [format_team_entity(team.reload)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create team: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def parse_member_ids(member_ids)
    return [] if member_ids.blank?

    if member_ids.is_a?(Array)
      member_ids.map(&:to_i)
    else
      JSON.parse(member_ids).map(&:to_i)
    end
  rescue JSON::ParserError
    []
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
