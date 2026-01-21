class Captain::Tools::Copilot::CreateScenarioService < Captain::Tools::BaseTool
  def self.name
    'create_scenario'
  end

  description <<~DESC
    Create a specialized Scenario for a Captain Assistant. Scenarios allow the assistant
    to handle specific types of requests with specialized instructions and tools.

    **Tool References:** Use [@ToolName](tool://tool_id) syntax in instructions to reference tools.

    **Example:**
    {
      "assistant_id": 1,
      "title": "Product Search",
      "description": "Handles product inquiries and searches",
      "instruction": "When customer asks about products, use [@Search Products](tool://search_products) to find them."
    }

    **Available tools for scenarios:**
    - search_products: Search products in the catalog
    - handoff: Transfer conversation to human agent
    - faq_lookup: Search FAQ/knowledge base
    - add_label_to_conversation: Add labels to conversation
    - add_private_note: Add internal notes
    - add_contact_note: Add notes to contact profile
    - update_priority: Update conversation priority

    **Common scenario patterns:**
    1. Product Search: Use search_products when customer asks about products
    2. Human Handoff: Use handoff when customer wants to talk to a human
    3. FAQ Response: Use faq_lookup to find answers from knowledge base
  DESC

  param :assistant_id, type: 'integer', desc: 'ID of the assistant to add the scenario to'
  param :title, type: 'string', desc: 'Title of the scenario (e.g., "Product Search", "Human Handoff")'
  param :description, type: 'string', desc: 'Brief description of what this scenario handles'
  param :instruction, type: 'string', desc: 'Detailed instructions for the assistant. Use [@Tool](tool://tool_id) to reference tools.'

  def execute(assistant_id:, title:, description:, instruction:)
    target = find_assistant(assistant_id)
    return target if target.is_a?(String)

    validation = validate_params(title, description, instruction)
    return validation if validation

    existing = find_existing_scenario(target, title)
    return duplicate_response(existing) if existing

    scenario = create_scenario(target, title, description, instruction)
    success_response(target, scenario)
  end

  def active?
    true
  end

  private

  def find_assistant(assistant_id)
    target = @assistant.account.captain_assistants.find_by(id: assistant_id)
    target || "Assistant with ID #{assistant_id} not found. Use list_assistants to see available assistants."
  end

  def validate_params(title, description, instruction)
    return 'Scenario title is required' if title.blank?
    return 'Scenario description is required' if description.blank?
    return 'Scenario instruction is required' if instruction.blank?

    nil
  end

  def find_existing_scenario(target, title)
    target.scenarios.find_by('LOWER(title) = ?', title.downcase)
  end

  def duplicate_response(existing)
    {
      'content' => "A scenario named '#{existing.title}' already exists (ID: #{existing.id}). Use a different title.",
      'entities' => [format_scenario_entity(existing)]
    }
  end

  def create_scenario(target, title, description, instruction)
    scenario = target.scenarios.create!(
      account_id: @assistant.account_id, title: title, description: description, instruction: instruction, enabled: true
    )
    Rails.logger.info { "#{self.class.name}: create_scenario #{scenario.id} for assistant #{target.id}" }
    scenario
  end

  def success_response(target, scenario)
    tools_info = scenario.tools&.any? ? " Tools detected: #{scenario.tools.join(', ')}." : ''
    {
      'content' => "Scenario '#{scenario.title}' created for '#{target.name}' (ID: #{scenario.id}).#{tools_info}",
      'entities' => [format_scenario_entity(scenario)]
    }
  end

  def format_scenario_entity(scenario)
    {
      'type' => 'captain_scenario', 'id' => scenario.id, 'title' => scenario.title,
      'assistant_id' => scenario.assistant_id, 'enabled' => scenario.enabled, 'tools' => scenario.tools || []
    }
  end
end
