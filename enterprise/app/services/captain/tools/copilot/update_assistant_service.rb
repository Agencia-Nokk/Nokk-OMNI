class Captain::Tools::Copilot::UpdateAssistantService < Captain::Tools::BaseTool
  def self.name
    'update_assistant'
  end

  description <<~DESC
    Update an existing Captain Assistant. Provide only the fields you want to update.

    Use list_assistants to find the assistant ID first.

    **Example - Update name and description:**
    { "assistant_id": 1, "name": "New Name", "description": "New description" }

    **Example - Update guidelines:**
    { "assistant_id": 1, "response_guidelines": "[\\"Be friendly\\", \\"Use emojis\\"]" }
  DESC

  param :assistant_id, type: 'integer', desc: 'ID of the assistant to update'
  param :name, type: 'string', desc: 'New name for the assistant', required: false
  param :description, type: 'string', desc: 'New description', required: false
  param :product_name, type: 'string', desc: 'New product/company name', required: false
  param :response_guidelines, type: 'string', desc: 'JSON array of new response guidelines', required: false
  param :guardrails, type: 'string', desc: 'JSON array of new guardrails', required: false

  def execute(assistant_id:, **params)
    target = @assistant.account.captain_assistants.find_by(id: assistant_id)
    return "Assistant with ID #{assistant_id} not found. Use list_assistants to see available assistants." unless target

    updates = build_updates(params, target)
    return 'No updates provided. Specify at least one field to update.' if updates.empty?

    target.update!(updates)
    log_update(assistant_id)
    { 'content' => "Assistant '#{target.name}' updated successfully.", 'entities' => [format_assistant_entity(target)] }
  end

  def active?
    true
  end

  private

  def log_update(assistant_id)
    Rails.logger.info { "#{self.class.name}: update_assistant #{assistant_id} for account #{@assistant.account_id}" }
  end

  def build_updates(params, target)
    updates = {}
    updates[:name] = params[:name] if params[:name].present?
    updates[:description] = params[:description] if params[:description].present?
    updates[:response_guidelines] = parse_json_array(params[:response_guidelines]) if params[:response_guidelines].present?
    updates[:guardrails] = parse_json_array(params[:guardrails]) if params[:guardrails].present?
    updates[:config] = build_config(target, params[:product_name]) if params[:product_name].present?
    updates
  end

  def build_config(target, product_name)
    config = target.config || {}
    config['product_name'] = product_name
    config
  end

  def parse_json_array(value)
    return value if value.is_a?(Array)

    JSON.parse(value)
  rescue JSON::ParserError
    []
  end

  def format_assistant_entity(assistant)
    { 'type' => 'captain_assistant', 'id' => assistant.id, 'name' => assistant.name }
  end
end
