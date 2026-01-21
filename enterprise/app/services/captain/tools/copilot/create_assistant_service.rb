class Captain::Tools::Copilot::CreateAssistantService < Captain::Tools::BaseTool
  def self.name
    'create_assistant'
  end

  description <<~DESC
    Create a new Captain Assistant (AI-powered bot) for automated customer support.

    **When to use:** Use this tool to create an AI assistant that can handle customer conversations automatically.

    **Example:**
    {
      "name": "Virtual Assistant",
      "description": "Customer support assistant specialized in pharmacy products",
      "product_name": "Pharmacy XYZ",
      "response_guidelines": ["Be cordial", "Use simple language"],
      "guardrails": ["Never give medical diagnoses"]
    }

    **Parameters:**
    - name: Display name for the assistant
    - description: Detailed description defining the assistant's persona and capabilities
    - product_name: Name of the product/company the assistant represents
    - response_guidelines: JSON array of guidelines for how the assistant should respond
    - guardrails: JSON array of restrictions the assistant must follow
  DESC

  param :name, type: 'string', desc: 'Name of the assistant'
  param :description, type: 'string', desc: 'Detailed description and persona of the assistant'
  param :product_name, type: 'string', desc: 'Name of the product/company the assistant represents', required: false
  param :response_guidelines, type: 'string', desc: 'JSON array of response guidelines', required: false
  param :guardrails, type: 'string', desc: 'JSON array of restrictions/guardrails', required: false

  def execute(name:, description:, product_name: nil, response_guidelines: nil, guardrails: nil)
    return 'Assistant name is required' if name.blank?
    return 'Assistant description is required' if description.blank?

    existing = find_existing_assistant(name)
    return duplicate_response(existing) if existing.present?

    new_assistant = create_assistant(name, description, product_name, response_guidelines, guardrails)
    log_creation(new_assistant)
    success_response(new_assistant)
  end

  def active?
    true
  end

  private

  def find_existing_assistant(name)
    @assistant.account.captain_assistants.find_by('LOWER(name) = ?', name.downcase)
  end

  def duplicate_response(existing)
    {
      'content' => "An assistant named '#{existing.name}' already exists (ID: #{existing.id}). " \
                   'Would you like to update it using update_assistant, or create one with a different name?',
      'entities' => [format_assistant_entity(existing)]
    }
  end

  def log_creation(new_assistant)
    Rails.logger.info { "#{self.class.name}: create_assistant for account #{@assistant.account_id} - #{new_assistant.id}" }
  end

  def success_response(new_assistant)
    {
      'content' => "Assistant '#{new_assistant.name}' created successfully (ID: #{new_assistant.id}). " \
                   'Use create_scenario to add specialized behaviors, then connect_assistant_to_inbox to activate it.',
      'entities' => [format_assistant_entity(new_assistant)]
    }
  end

  def parse_json_array(value)
    return [] if value.blank?
    return value if value.is_a?(Array)

    JSON.parse(value)
  rescue JSON::ParserError
    []
  end

  def create_assistant(name, description, product_name, response_guidelines, guardrails)
    @assistant.account.captain_assistants.create!(
      name: name,
      description: description,
      config: { 'product_name' => product_name, 'temperature' => 0.7, 'feature_faq' => true, 'feature_memory' => true },
      response_guidelines: parse_json_array(response_guidelines),
      guardrails: parse_json_array(guardrails)
    )
  end

  def format_assistant_entity(assistant)
    { 'type' => 'captain_assistant', 'id' => assistant.id, 'name' => assistant.name, 'description' => assistant.description&.truncate(100) }
  end
end
