class Captain::Tools::Copilot::CreateCustomAttributeService < Captain::Tools::BaseTool
  def self.name
    'create_custom_attribute'
  end

  description <<~DESC
    Create a new custom attribute definition for conversations or contacts.

    **Parameters:**
    - attribute_display_name: Required. Display name shown in the UI.
    - attribute_key: Required. Unique key for the attribute (lowercase, no spaces, use underscores).
    - attribute_model: Required. Either "conversation" or "contact".
    - attribute_display_type: Required. Type of the attribute:
      - "text" - Free text field
      - "number" - Numeric value
      - "currency" - Currency amount
      - "percent" - Percentage value
      - "link" - URL link
      - "date" - Date picker
      - "list" - Dropdown list (requires attribute_values)
      - "checkbox" - Boolean checkbox
    - attribute_description: Optional. Description of the attribute.
    - attribute_values: Optional. JSON array of values for "list" type (e.g., '["High", "Medium", "Low"]').
  DESC

  param :attribute_display_name, type: :string, desc: 'Display name for the attribute'
  param :attribute_key, type: :string, desc: 'Unique key (lowercase, underscores)'
  param :attribute_model, type: :string, desc: '"conversation" or "contact"'
  param :attribute_display_type, type: :string, desc: 'Type: text, number, currency, percent, link, date, list, checkbox'
  param :attribute_description, type: :string, desc: 'Description of the attribute', required: false
  param :attribute_values, type: :string, desc: 'JSON array of values for list type', required: false

  def execute(attribute_display_name:, attribute_key:, attribute_model:, attribute_display_type:, attribute_description: nil, attribute_values: nil)
    return 'Display name is required' if attribute_display_name.blank?
    return 'Attribute key is required' if attribute_key.blank?

    model_type = parse_model_type(attribute_model)
    return 'Invalid attribute model. Use "conversation" or "contact"' unless model_type

    display_type = parse_display_type(attribute_display_type)
    return 'Invalid display type. Use: text, number, currency, percent, link, date, list, checkbox' unless display_type

    existing = @assistant.account.custom_attribute_definitions.find_by(
      attribute_key: attribute_key.downcase,
      attribute_model: model_type
    )

    if existing.present?
      return {
        'content' => "A custom attribute with key '#{attribute_key}' already exists for #{attribute_model}.",
        'entities' => [format_attribute_entity(existing)]
      }
    end

    attrs = {
      attribute_display_name: attribute_display_name.strip,
      attribute_key: attribute_key.downcase.strip.gsub(/\s+/, '_'),
      attribute_model: model_type,
      attribute_display_type: display_type
    }

    attrs[:attribute_description] = attribute_description if attribute_description.present?
    attrs[:attribute_values] = parse_values(attribute_values) if attribute_values.present? && display_type == :list

    attr = @assistant.account.custom_attribute_definitions.create!(attrs)

    {
      'content' => "Custom attribute '#{attr.attribute_display_name}' created successfully for #{attr.attribute_model.humanize}.",
      'entities' => [format_attribute_entity(attr)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create custom attribute: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
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

  def parse_display_type(type)
    valid_types = %w[text number currency percent link date list checkbox]
    type = type.to_s.downcase
    type.to_sym if valid_types.include?(type)
  end

  def parse_values(values)
    return values if values.is_a?(Array)

    JSON.parse(values)
  rescue JSON::ParserError
    []
  end

  def format_attribute_entity(attr)
    {
      'type' => 'custom_attribute',
      'id' => attr.id,
      'name' => attr.attribute_display_name,
      'key' => attr.attribute_key,
      'model' => attr.attribute_model,
      'display_type' => attr.attribute_display_type
    }
  end
end
