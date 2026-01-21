class Captain::Tools::Copilot::GetCustomAttributeService < Captain::Tools::BaseTool
  def self.name
    'get_custom_attribute'
  end

  description 'Get details of a specific custom attribute by ID or key'

  param :attribute_id, type: :number, desc: 'ID of the custom attribute', required: false
  param :attribute_key, type: :string, desc: 'Key of the custom attribute', required: false

  def execute(attribute_id: nil, attribute_key: nil)
    attr = find_attribute(attribute_id, attribute_key)
    return 'Custom attribute not found' unless attr

    {
      'content' => build_attribute_details(attr),
      'entities' => [format_attribute_entity(attr)]
    }
  end

  def active?
    true
  end

  private

  def find_attribute(attribute_id, attribute_key)
    attributes = @assistant.account.custom_attribute_definitions

    if attribute_id
      attributes.find_by(id: attribute_id)
    elsif attribute_key
      attributes.find_by(attribute_key: attribute_key)
    end
  end

  def build_attribute_details(attr)
    values_section = attr.attribute_values.present? ? "\n**Values:** #{attr.attribute_values.join(', ')}" : ''
    regex_section = attr.regex_pattern.present? ? "\n**Regex pattern:** #{attr.regex_pattern}" : ''

    <<~DETAILS.strip
      Custom attribute details:

      **Display name:** #{attr.attribute_display_name}
      **Key:** #{attr.attribute_key}
      **Model:** #{attr.attribute_model.humanize}
      **Type:** #{attr.attribute_display_type}
      **Description:** #{attr.attribute_description || 'N/A'}#{values_section}#{regex_section}
    DETAILS
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
