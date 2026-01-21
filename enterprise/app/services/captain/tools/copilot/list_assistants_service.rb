class Captain::Tools::Copilot::ListAssistantsService < Captain::Tools::BaseTool
  def self.name
    'list_assistants'
  end

  description <<~DESC
    List all Captain Assistants (AI bots) available in the account.

    Returns assistant ID, name, and connected inboxes. Use this to find assistant IDs
    before creating scenarios or connecting to inboxes.
  DESC

  def execute
    assistants = @assistant.account.captain_assistants.ordered.includes(:inboxes)

    return 'No assistants found in this account. Use create_assistant to create one.' if assistants.empty?

    {
      'content' => format_assistants_list(assistants),
      'entities' => assistants.map { |a| format_assistant_entity(a) }
    }
  end

  def active?
    true
  end

  private

  def format_assistants_list(assistants)
    lines = assistants.map do |a|
      inboxes = a.inboxes.pluck(:name)
      inbox_info = inboxes.any? ? " - Connected to: #{inboxes.join(', ')}" : ' - No inboxes connected'
      scenarios_count = a.scenarios.count
      scenario_info = scenarios_count.positive? ? " (#{scenarios_count} scenarios)" : ''

      "- **#{a.name}** (ID: #{a.id})#{scenario_info}#{inbox_info}"
    end

    "Found #{assistants.size} assistant(s):\n\n#{lines.join("\n")}"
  end

  def format_assistant_entity(assistant)
    {
      'type' => 'captain_assistant',
      'id' => assistant.id,
      'name' => assistant.name,
      'scenarios_count' => assistant.scenarios.count,
      'inboxes_count' => assistant.inboxes.count
    }
  end
end
