class Captain::Tools::Copilot::ListCustomRolesService < Captain::Tools::BaseTool
  def self.name
    'list_custom_roles'
  end

  description 'List all custom roles available in the account with their permissions'

  def execute
    custom_roles = @assistant.account.custom_roles
    return 'No custom roles found in this account' if custom_roles.empty?

    {
      'content' => "Found #{custom_roles.count} custom role(s):",
      'entities' => custom_roles.map { |role| format_custom_role_entity(role) }
    }
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
      'permissions_count' => custom_role.permissions.size
    }
  end
end
