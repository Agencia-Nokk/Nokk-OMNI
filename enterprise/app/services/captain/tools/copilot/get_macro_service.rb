class Captain::Tools::Copilot::GetMacroService < Captain::Tools::BaseTool
  def self.name
    'get_macro'
  end

  description <<~DESC
    Get full details of a specific macro including all actions and their parameters.
    Use this to see the complete configuration of a macro before updating it.
  DESC

  param :macro_id, type: :integer, desc: 'ID of the macro to retrieve', required: true

  def execute(macro_id:)
    macro = @assistant.account.macros.find_by(id: macro_id)
    return "Macro with ID #{macro_id} not found" if macro.blank?

    {
      'content' => format_macro_details(macro),
      'entities' => [format_macro_entity(macro)]
    }
  end

  def active?
    true
  end

  private

  def format_macro_details(macro)
    actions_detail = macro.actions.map.with_index(1) do |action, idx|
      params = action['action_params']&.join(', ') || 'none'
      "  #{idx}. #{action['action_name']}: [#{params}]"
    end.join("\n")

    <<~DETAILS.strip
      **Name:** #{macro.name}
      **Visibility:** #{macro.visibility}
      **Created by:** #{macro.created_by&.name || 'Unknown'}
      **Actions:**
      #{actions_detail}
    DETAILS
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
end
