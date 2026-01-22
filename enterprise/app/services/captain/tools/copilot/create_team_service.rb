class Captain::Tools::Copilot::CreateTeamService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TeamHelpers

  def self.name
    'create_team'
  end

  description <<~DESC
    Create a new team in the account. Teams are used to group agents and route conversations efficiently.

    **When to use:** Use this tool when you need to organize agents into groups for better conversation routing. For example: creating specialized support teams, regional teams, or skill-based groups.

    **Complete Example:**
    To create a billing support team with specific members:
    {
      "name": "billing-support",
      "description": "Handles payment and subscription issues",
      "allow_auto_assign": true,
      "member_ids": "[1, 5, 12]"
    }

    **Parameters:**
    - name: Team name (will be converted to lowercase, use hyphens for spaces)
    - description: Purpose of the team
    - allow_auto_assign: Auto-distribute new conversations among team members (default: true)
    - member_ids: JSON array of agent IDs (use list_agents to find IDs)

    **Common Use Cases:**
    1. Sales Team: name="sales", allow_auto_assign=true, member_ids="[1, 2, 3]"
    2. Technical Support: name="tech-support", description="L2 technical issues", allow_auto_assign=true
    3. VIP Support: name="vip-support", description="Premium customers only", allow_auto_assign=false
    4. Regional Team: name="latam-support", description="Latin America support team"

    **Tip:** Use allow_auto_assign=false for teams where conversations need manual assignment (e.g., VIP support).
    For more details: https://www.chatwoot.com/docs/product/features/teams
  DESC

  param :name, type: :string, desc: 'Team name'
  param :description, type: :string, desc: 'Team description', required: false
  param :allow_auto_assign, type: :boolean, desc: 'Enable auto-assignment (default: true)', required: false
  param :member_ids, type: :string, desc: 'JSON array of agent IDs to add as members', required: false

  def execute(name:, description: nil, allow_auto_assign: nil, member_ids: nil)
    validation = validate_team_name(name)
    return validation if validation

    create_team_with_members(name, description, allow_auto_assign, member_ids)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create team: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def validate_team_name(name)
    return 'Team name is required' if name.blank?

    existing = @assistant.account.teams.find_by(name: name.downcase)
    return if existing.blank?

    {
      'content' => "A team with name '#{name}' already exists.",
      'entities' => [format_team_entity(existing)]
    }
  end

  def create_team_with_members(name, description, allow_auto_assign, member_ids)
    attrs = build_team_attrs(name, description, allow_auto_assign)
    team = @assistant.account.teams.create!(attrs)
    add_team_members(team, member_ids)

    {
      'content' => "Team '#{team.name}' created successfully with #{team.members.count} member(s).",
      'entities' => [format_team_entity(team.reload)]
    }
  end

  def build_team_attrs(name, description, allow_auto_assign)
    attrs = { name: name.downcase.strip }
    attrs[:description] = description if description.present?
    attrs[:allow_auto_assign] = allow_auto_assign unless allow_auto_assign.nil?
    attrs
  end

  def add_team_members(team, member_ids)
    return if member_ids.blank?

    ids = parse_member_ids(member_ids)
    team.add_members(ids) if ids.any?
  end
end
