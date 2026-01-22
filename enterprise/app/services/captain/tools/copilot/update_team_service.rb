class Captain::Tools::Copilot::UpdateTeamService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TeamHelpers

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

  # rubocop:disable Metrics/ParameterLists
  def execute(team_id:, name: nil, description: nil, allow_auto_assign: nil, add_member_ids: nil, remove_member_ids: nil)
    team = find_team_by_id_or_name(team_id: team_id)
    return 'Team not found' unless team

    params = { name: name, description: description, allow_auto_assign: allow_auto_assign,
               add_member_ids: add_member_ids, remove_member_ids: remove_member_ids }
    result = update_team_with_members(team, params)
    return result if result.is_a?(String)

    success_response(team)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update team: #{e.message}"
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    user_has_permission('administrator')
  end

  private

  def update_team_with_members(team, params)
    attrs = build_team_attrs(params[:name], params[:description], params[:allow_auto_assign])
    has_member_changes = params[:add_member_ids].present? || params[:remove_member_ids].present?

    return 'No changes provided' if attrs.empty? && !has_member_changes

    team.update!(attrs) if attrs.present?
    manage_members(team, params[:add_member_ids], params[:remove_member_ids])
  end

  def build_team_attrs(name, description, allow_auto_assign)
    attrs = {}
    attrs[:name] = name.downcase.strip if name.present?
    attrs[:description] = description if description.present?
    attrs[:allow_auto_assign] = allow_auto_assign unless allow_auto_assign.nil?
    attrs
  end

  def manage_members(team, add_ids, remove_ids)
    add_team_members(team, add_ids)
    remove_team_members(team, remove_ids)
  end

  def add_team_members(team, add_ids)
    return unless add_ids.present?

    ids = parse_member_ids(add_ids)
    team.add_members(ids) if ids.any?
  end

  def remove_team_members(team, remove_ids)
    return unless remove_ids.present?

    ids = parse_member_ids(remove_ids)
    team.remove_members(ids) if ids.any?
  end

  def success_response(team)
    {
      'content' => "Team '#{team.reload.name}' updated successfully. Current members: #{team.members.count}",
      'entities' => [format_team_entity(team)]
    }
  end
end
