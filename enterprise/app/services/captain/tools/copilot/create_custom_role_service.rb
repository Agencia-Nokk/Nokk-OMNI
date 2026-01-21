class Captain::Tools::Copilot::CreateCustomRoleService < Captain::Tools::BaseTool
  def self.name
    'create_custom_role'
  end

  description <<~DESC
    Create a new custom role with specific permissions. Custom roles allow fine-grained access control for agents.

    **Available Permissions:**
    - conversation_manage: Can manage all conversations
    - conversation_unassigned_manage: Can manage unassigned conversations and assign to self
    - conversation_participating_manage: Can manage conversations they are participating in
    - contact_manage: Can manage contacts
    - report_manage: Can manage reports
    - knowledge_base_manage: Can manage knowledge base portals

    **Parameters:**
    - name: Required. The name of the custom role
    - description: Optional. Description of what this role is for
    - permissions: Required. Array of permission strings from the list above
  DESC

  param :name, type: :string, desc: 'Name of the custom role'
  param :description, type: :string, desc: 'Description of the custom role', required: false
  param :permissions, type: :array, desc: 'Array of permissions (e.g., ["conversation_manage", "contact_manage"])'

  VALID_PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
    contact_manage
    report_manage
    knowledge_base_manage
  ].freeze

  def execute(name:, permissions:, description: nil)
    return 'Custom role name is required' if name.blank?
    return 'At least one permission is required' if permissions.blank? || permissions.empty?

    invalid_perms = permissions - VALID_PERMISSIONS
    return "Invalid permissions: #{invalid_perms.join(', ')}. Valid permissions are: #{VALID_PERMISSIONS.join(', ')}" if invalid_perms.any?

    attrs = {
      name: name.strip,
      permissions: permissions
    }
    attrs[:description] = description if description.present?

    custom_role = @assistant.account.custom_roles.create!(attrs)

    {
      'content' => "Custom role '#{custom_role.name}' created successfully with #{custom_role.permissions.size} permission(s)",
      'entities' => [format_custom_role_entity(custom_role)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create custom role: #{e.message}"
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
