class Captain::Tools::Copilot::CreateCustomAttributeService < Captain::Tools::BaseTool
  VALID_DISPLAY_TYPES = %w[text number currency percent link date list checkbox].freeze

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

  # rubocop:disable Metrics/ParameterLists
  def execute(attribute_display_name:, attribute_key:, attribute_model:, attribute_display_type:,
              attribute_description: nil, attribute_values: nil)
    validation = validate_params(attribute_display_name, attribute_key, attribute_model, attribute_display_type)
    return validation unless validation.is_a?(Array)

    model_type, display_type = validation
    params = { display_name: attribute_display_name, key: attribute_key, model_type: model_type,
               display_type: display_type, description: attribute_description, values: attribute_values }
    create_attribute(params)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create custom attribute: #{e.message}"
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    user_has_permission('administrator')
  end

  private

  def validate_params(display_name, key, model, display_type)
    return 'Display name is required' if display_name.blank?
    return 'Attribute key is required' if key.blank?

    model_type = parse_model_type(model)
    return 'Invalid attribute model. Use "conversation" or "contact"' unless model_type

    parsed_type = parse_display_type(display_type)
    return 'Invalid display type. Use: text, number, currency, percent, link, date, list, checkbox' unless parsed_type

    existing = find_existing_attribute(key, model_type)
    return existing_response(existing, model) if existing.present?

    [model_type, parsed_type]
  end

  def find_existing_attribute(key, model_type)
    @assistant.account.custom_attribute_definitions.find_by(
      attribute_key: key.downcase,
      attribute_model: model_type
    )
  end

  def existing_response(attr, model)
    {
      'content' => "A custom attribute with key '#{attr.attribute_key}' already exists for #{model}.",
      'entities' => [format_attribute_entity(attr)]
    }
  end

  def create_attribute(params)
    attrs = build_attrs(params)
    attr = @assistant.account.custom_attribute_definitions.create!(attrs)

    {
      'content' => "Custom attribute '#{attr.attribute_display_name}' created successfully for #{attr.attribute_model.humanize}.",
      'entities' => [format_attribute_entity(attr)]
    }
  end

  def build_attrs(params)
    attrs = {
      attribute_display_name: params[:display_name].strip,
      attribute_key: params[:key].downcase.strip.gsub(/\s+/, '_'),
      attribute_model: params[:model_type],
      attribute_display_type: params[:display_type]
    }
    attrs[:attribute_description] = params[:description] if params[:description].present?
    attrs[:attribute_values] = parse_values(params[:values]) if params[:values].present? && params[:display_type] == :list
    attrs
  end

  def parse_model_type(model)
    case model.to_s.downcase
    when 'conversation', 'conversation_attribute' then :conversation_attribute
    when 'contact', 'contact_attribute' then :contact_attribute
    end
  end

  def parse_display_type(type)
    type = type.to_s.downcase
    type.to_sym if VALID_DISPLAY_TYPES.include?(type)
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
