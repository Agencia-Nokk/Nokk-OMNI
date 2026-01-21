class Captain::Tools::Copilot::UpdateMacroService < Captain::Tools::BaseTool
  def self.name
    'update_macro'
  end

  description <<~DESC
    Update an existing macro. You can update the name and/or actions.

    **Important**: Before updating a macro with assign_agent or assign_team actions,
    use list_agents or list_teams to get the correct IDs.

    To update actions, provide the complete new actions array (it replaces the existing one).
    If you only want to update the name, omit the actions parameter.

    Example - Update name only:
    { "macro_id": 1, "name": "New name" }

    Example - Update actions:
    { "macro_id": 1, "actions": [{"action_name": "assign_agent", "action_params": [123]}] }
  DESC

  param :macro_id, type: :integer, desc: 'ID of the macro to update', required: true
  param :name, type: 'string', desc: 'New name for the macro (optional)', required: false
  param :actions, type: 'string', desc: 'JSON string with new actions array (optional, replaces existing)', required: false

  def execute(macro_id:, name: nil, actions: nil)
    macro = @assistant.account.macros.find_by(id: macro_id)
    return "Macro with ID #{macro_id} not found" if macro.blank?

    updates = {}
    updates[:name] = name if name.present?

    if actions.present?
      parsed_actions = parse_json_param(actions, 'actions')
      return parsed_actions if parsed_actions.is_a?(String)

      normalized_actions = normalize_actions(parsed_actions)
      return normalized_actions if normalized_actions.is_a?(String)

      updates[:actions] = normalized_actions
    end

    return 'No updates provided. Specify name and/or actions to update.' if updates.empty?

    macro.update!(updates)

    {
      'content' => "Macro '#{macro.name}' updated successfully",
      'entities' => [format_macro_entity(macro)]
    }
  end

  def format_macro_entity(macro)
    {
      'type' => 'macro',
      'id' => macro.id,
      'name' => macro.name,
      'visibility' => macro.visibility,
      'actions_count' => macro.actions.size
    }
  end

  def active?
    true
  end

  private

  def parse_json_param(value, param_name)
    return value if value.is_a?(Array)

    JSON.parse(value)
  rescue JSON::ParserError
    "Invalid JSON for #{param_name}. Please provide a valid JSON array."
  end

  def normalize_actions(actions)
    return 'Actions must be an array' unless actions.is_a?(Array)
    return 'At least one action is required' if actions.empty?

    actions.map do |action|
      action = action.with_indifferent_access
      action_name = action[:action_name]

      return "Invalid action '#{action_name}'. Valid: #{Macro::ACTIONS_ATTRS.join(', ')}" unless Macro::ACTIONS_ATTRS.include?(action_name)

      action_params = resolve_action_params(action_name, action[:action_params])
      return action_params if action_params.is_a?(String) && action_params.start_with?('Error:')

      { 'action_name' => action_name, 'action_params' => action_params }
    end
  end

  def resolve_action_params(action_name, params)
    case action_name
    when 'assign_agent'
      resolve_agent_param(params)
    when 'assign_team'
      resolve_team_param(params)
    else
      Array(params)
    end
  end

  def resolve_agent_param(params)
    return Array(params) if params.blank?

    param = params.first
    return [param] if param.is_a?(Integer) || param.to_s.match?(/^\d+$/)
    return ['self'] if param.to_s.downcase == 'self'

    # Try to find agent by name or email
    agent = @assistant.account.users.find_by('LOWER(name) = ? OR LOWER(email) = ?',
                                             param.to_s.downcase, param.to_s.downcase)
    return "Error: Agent '#{param}' not found. Use list_agents to see available agents." if agent.blank?

    [agent.id]
  end

  def resolve_team_param(params)
    return Array(params) if params.blank?

    param = params.first
    return [param.to_i] if param.is_a?(Integer) || param.to_s.match?(/^\d+$/)

    # Try to find team by name
    team = @assistant.account.teams.find_by('LOWER(name) = ?', param.to_s.downcase)
    return "Error: Team '#{param}' not found. Use list_teams to see available teams." if team.blank?

    [team.id]
  end
end
