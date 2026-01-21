class Captain::Tools::Copilot::ListScenariosService < Captain::Tools::BaseTool
  def self.name
    'list_scenarios'
  end

  description <<~DESC
    List all Scenarios for a Captain Assistant.

    Use list_assistants first to find the assistant ID.

    Returns scenario ID, title, status (enabled/disabled), and tools used.
  DESC

  param :assistant_id, type: 'integer', desc: 'ID of the assistant to list scenarios for'

  def execute(assistant_id:)
    target = @assistant.account.captain_assistants.find_by(id: assistant_id)
    return "Assistant with ID #{assistant_id} not found. Use list_assistants to see available assistants." unless target

    scenarios = target.scenarios

    return "No scenarios found for assistant '#{target.name}'. Use create_scenario to add one." if scenarios.empty?

    {
      'content' => format_scenarios_list(target, scenarios),
      'entities' => scenarios.map { |s| format_scenario_entity(s) }
    }
  end

  def active?
    true
  end

  private

  def format_scenarios_list(assistant, scenarios)
    lines = scenarios.map do |s|
      status = s.enabled? ? '✅ Enabled' : '❌ Disabled'
      tools_info = s.tools&.any? ? " - Tools: #{s.tools.join(', ')}" : ''

      "- **#{s.title}** (ID: #{s.id}) - #{status}#{tools_info}"
    end

    "Scenarios for '#{assistant.name}':\n\n#{lines.join("\n")}"
  end

  def format_scenario_entity(scenario)
    {
      'type' => 'captain_scenario',
      'id' => scenario.id,
      'title' => scenario.title,
      'enabled' => scenario.enabled,
      'tools' => scenario.tools || []
    }
  end
end
