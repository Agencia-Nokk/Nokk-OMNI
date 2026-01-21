class Captain::Tools::Copilot::UpdateCustomAttributeService < Captain::Tools::BaseTool
  def self.name
    'update_custom_attribute'
  end

  description <<~DESC
    Update an existing custom attribute definition.

    **Note:** You cannot change the attribute_key or attribute_model after creation.
  DESC

  param :attribute_id, type: :number, desc: 'ID of the custom attribute to update'
  param :attribute_display_name, type: :string, desc: 'New display name', required: false
  param :attribute_description, type: :string, desc: 'New description', required: false
  param :attribute_values, type: :string, desc: 'JSON array of values for list type', required: false

  def execute(attribute_id:, attribute_display_name: nil, attribute_description: nil, attribute_values: nil)
    attr = @assistant.account.custom_attribute_definitions.find_by(id: attribute_id)
    return 'Custom attribute not found' unless attr

    attrs = {}
    attrs[:attribute_display_name] = attribute_display_name.strip if attribute_display_name.present?
    attrs[:attribute_description] = attribute_description if attribute_description.present?
    attrs[:attribute_values] = parse_values(attribute_values) if attribute_values.present?

    return 'No changes provided' if attrs.empty?

    attr.update!(attrs)

    {
      'content' => "Custom attribute '#{attr.reload.attribute_display_name}' updated successfully",
      'entities' => [format_attribute_entity(attr)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update custom attribute: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

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
