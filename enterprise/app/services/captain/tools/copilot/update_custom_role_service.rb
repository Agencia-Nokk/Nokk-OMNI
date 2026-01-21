class Captain::Tools::Copilot::UpdateCustomRoleService < Captain::Tools::BaseTool
  def self.name
    'update_custom_role'
  end

  description <<~DESC
    Update an existing custom role. You can update the name, description, or permissions.

    **Available Permissions:**
    - conversation_manage: Can manage all conversations
    - conversation_unassigned_manage: Can manage unassigned conversations and assign to self
    - conversation_participating_manage: Can manage conversations they are participating in
    - contact_manage: Can manage contacts
    - report_manage: Can manage reports
    - knowledge_base_manage: Can manage knowledge base portals

    Note: Updating permissions will affect all agents assigned to this role.
  DESC

  param :custom_role_id, type: :integer, desc: 'ID of the custom role to update'
  param :name, type: :string, desc: 'New name for the custom role', required: false
  param :description, type: :string, desc: 'New description', required: false
  param :permissions, type: :array, desc: 'New array of permissions', required: false

  VALID_PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
    contact_manage
    report_manage
    knowledge_base_manage
  ].freeze

  def execute(custom_role_id:, name: nil, description: nil, permissions: nil)
    custom_role = @assistant.account.custom_roles.find_by(id: custom_role_id)
    return 'Custom role not found' unless custom_role

    attrs = {}
    attrs[:name] = name.strip if name.present?
    attrs[:description] = description if description.present?

    if permissions.present?
      invalid_perms = permissions - VALID_PERMISSIONS
      return "Invalid permissions: #{invalid_perms.join(', ')}. Valid permissions are: #{VALID_PERMISSIONS.join(', ')}" if invalid_perms.any?

      attrs[:permissions] = permissions
    end

    return 'No changes provided' if attrs.empty?

    custom_role.update!(attrs)

    {
      'content' => "Custom role '#{custom_role.name}' updated successfully",
      'entities' => [format_custom_role_entity(custom_role)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update custom role: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def format_custom_role_entity(custom_role)
    {
      'type' => 'custom_role',
      'id' => custom_role.id,
      'name' => custom_role.name,
      'description' => custom_role.description,
      'permissions' => custom_role.permissions
    }
  end
end
