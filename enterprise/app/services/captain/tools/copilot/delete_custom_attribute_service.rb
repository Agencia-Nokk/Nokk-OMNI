class Captain::Tools::Copilot::DeleteCustomAttributeService < Captain::Tools::BaseTool
  def self.name
    'delete_custom_attribute'
  end

  description <<~DESC
    Delete a custom attribute definition from the account.

    **Warning:** This will remove the attribute definition. Existing data stored in
    conversations or contacts using this attribute will remain but will no longer
    be associated with a definition.
  DESC

  param :attribute_id, type: :number, desc: 'ID of the custom attribute to delete'

  def execute(attribute_id:)
    attr = @assistant.account.custom_attribute_definitions.find_by(id: attribute_id)
    return 'Custom attribute not found' unless attr

    display_name = attr.attribute_display_name
    attr.destroy!

    "Custom attribute '#{display_name}' deleted successfully"
  end

  def active?
    user_has_permission('administrator')
  end
end
