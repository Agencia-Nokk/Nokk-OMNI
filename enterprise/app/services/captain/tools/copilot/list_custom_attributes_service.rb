class Captain::Tools::Copilot::ListCustomAttributesService < Captain::Tools::BaseTool
  def self.name
    'list_custom_attributes'
  end

  description <<~DESC
    List all custom attribute definitions in the account. Custom attributes allow you to
    store additional information on conversations and contacts.

    **Optional filter:**
    - attribute_model: Filter by "conversation" or "contact" attributes.
  DESC

  param :attribute_model, type: :string, desc: 'Filter by model: "conversation" or "contact"', required: false

  def execute(attribute_model: nil)
    attributes = @assistant.account.custom_attribute_definitions

    if attribute_model.present?
      model_type = parse_model_type(attribute_model)
      return 'Invalid attribute model. Use "conversation" or "contact"' unless model_type

      attributes = attributes.where(attribute_model: model_type)
    end

    return 'No custom attributes found' if attributes.empty?

    {
      'content' => "Found #{attributes.count} custom attribute(s):",
      'entities' => attributes.map { |attr| format_attribute_entity(attr) }
    }
  end

  def active?
    true
  end

  private

  def parse_model_type(model)
    case model.to_s.downcase
    when 'conversation', 'conversation_attribute'
      :conversation_attribute
    when 'contact', 'contact_attribute'
      :contact_attribute
    end
  end

  def format_attribute_entity(attr)
    {
      'type' => 'custom_attribute',
      'id' => attr.id,
      'name' => attr.attribute_display_name,
      'key' => attr.attribute_key,
      'model' => attr.attribute_model,
      'display_type' => attr.attribute_display_type,
      'description' => attr.attribute_description
    }
  end
end
