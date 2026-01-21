class Captain::Tools::Copilot::UpdateTeamService < Captain::Tools::BaseTool
  def self.name
    'update_team'
  end

  description <<~DESC
    Update an existing team. You can update name, description, auto-assign setting, or manage members.

    **Parameters:**
    - team_id: Required. ID of the team to update.
    - name: Optional. New name for the team.
    - description: Optional. New description.
    - allow_auto_assign: Optional. Enable/disable auto-assignment.
    - add_member_ids: Optional. JSON array of agent IDs to add as members.
    - remove_member_ids: Optional. JSON array of agent IDs to remove from members.
  DESC

  param :team_id, type: :number, desc: 'ID of the team to update'
  param :name, type: :string, desc: 'New name for the team', required: false
  param :description, type: :string, desc: 'New description', required: false
  param :allow_auto_assign, type: :boolean, desc: 'Enable auto-assignment', required: false
  param :add_member_ids, type: :string, desc: 'JSON array of agent IDs to add', required: false
  param :remove_member_ids, type: :string, desc: 'JSON array of agent IDs to remove', required: false

  def execute(team_id:, name: nil, description: nil, allow_auto_assign: nil, add_member_ids: nil, remove_member_ids: nil)
    team = @assistant.account.teams.find_by(id: team_id)
    return 'Team not found' unless team

    attrs = {}
    attrs[:name] = name.downcase.strip if name.present?
    attrs[:description] = description if description.present?
    attrs[:allow_auto_assign] = allow_auto_assign unless allow_auto_assign.nil?

    has_member_changes = add_member_ids.present? || remove_member_ids.present?

    return 'No changes provided' if attrs.empty? && !has_member_changes

    team.update!(attrs) if attrs.present?

    # Manage members
    if add_member_ids.present?
      ids = parse_member_ids(add_member_ids)
      team.add_members(ids) if ids.any?
    end

    if remove_member_ids.present?
      ids = parse_member_ids(remove_member_ids)
      team.remove_members(ids) if ids.any?
    end

    {
      'content' => "Team '#{team.reload.name}' updated successfully. Current members: #{team.members.count}",
      'entities' => [format_team_entity(team)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update team: #{e.message}"
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
