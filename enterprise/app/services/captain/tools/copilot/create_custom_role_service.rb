class Captain::Tools::Copilot::CreateCustomRoleService < Captain::Tools::BaseTool
  def self.name
    'create_custom_role'
  end

  description <<~DESC
    Create a new custom role with specific permissions. Custom roles allow fine-grained access control for agents beyond the default "agent" and "administrator" roles.

    **When to use:** Use this tool when you need to create specialized roles with limited access. For example: support-only agents, team leads with reporting access, or content managers for knowledge base.

    **Complete Example:**
    To create a "Support Lead" role that can manage conversations and view reports:
    {
      "name": "Support Lead",
      "description": "Team leads who manage conversations and view reports",
      "permissions": ["conversation_manage", "report_manage"]
    }

    **Available Permissions:**
    - conversation_manage: Full access to all conversations (view, assign, resolve)
    - conversation_unassigned_manage: Can only manage unassigned conversations and assign to self
    - conversation_participating_manage: Can only manage conversations they are participating in
    - contact_manage: Can view, create, edit, and delete contacts
    - report_manage: Can access and export reports
    - knowledge_base_manage: Can manage help center portals and articles

    **Common Use Cases:**
    1. Basic Agent: ["conversation_participating_manage"] - Only handle assigned conversations
    2. Support Lead: ["conversation_manage", "report_manage"] - Manage all conversations + reports
    3. Content Manager: ["knowledge_base_manage"] - Only manage help center content
    4. Full Support: ["conversation_manage", "contact_manage"] - Conversations + contacts
    5. Team Manager: ["conversation_manage", "contact_manage", "report_manage"] - Full support access

    For more details: https://www.chatwoot.com/docs/product/features/custom-roles
  DESC

  param :name, type: :string, desc: 'Name of the custom role'
  param :description, type: :string, desc: 'Description of the custom role', required: false
  param :permissions, type: :string, desc: 'JSON array of permissions (e.g., ["conversation_manage", "contact_manage"])'

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
    return 'Permissions JSON array is required' if permissions.blank?

    parsed_permissions = parse_permissions(permissions)
    return parsed_permissions if parsed_permissions.is_a?(String)

    custom_role = create_role(name, parsed_permissions, description)
    build_success_response(custom_role)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create custom role: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def parse_permissions(permissions)
    parsed = JSON.parse(permissions)
    return 'At least one permission is required' if parsed.empty?

    invalid_perms = parsed - VALID_PERMISSIONS
    return "Invalid permissions: #{invalid_perms.join(', ')}. Valid: #{VALID_PERMISSIONS.join(', ')}" if invalid_perms.any?

    parsed
  rescue JSON::ParserError
    'Invalid JSON format for permissions. Expected format: ["permission1", "permission2"]'
  end

  def create_role(name, permissions, description)
    attrs = { name: name.strip, permissions: permissions }
    attrs[:description] = description if description.present?
    @assistant.account.custom_roles.create!(attrs)
  end

  def build_success_response(custom_role)
    {
      'content' => "Custom role '#{custom_role.name}' created successfully with #{custom_role.permissions.size} permission(s)",
      'entities' => [format_custom_role_entity(custom_role)]
    }
  end

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
