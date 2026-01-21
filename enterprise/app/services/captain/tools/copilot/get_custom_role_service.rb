class Captain::Tools::Copilot::GetCustomRoleService < Captain::Tools::BaseTool
  def self.name
    'get_custom_role'
  end

  description <<~DESC
    Get full details of a specific custom role including all permissions.
    Use this to see the complete configuration before updating.
  DESC

  param :custom_role_id, type: :integer, desc: 'ID of the custom role to retrieve', required: true

  def execute(custom_role_id:)
    custom_role = @assistant.account.custom_roles.find_by(id: custom_role_id)
    return "Custom role with ID #{custom_role_id} not found" if custom_role.blank?

    {
      'content' => format_role_details(custom_role),
      'entities' => [format_custom_role_entity(custom_role)]
    }
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def format_role_details(custom_role)
    permissions_list = custom_role.permissions.map.with_index(1) do |perm, idx|
      "  #{idx}. #{perm}"
    end.join("\n")

    <<~DETAILS.strip
      **Name:** #{custom_role.name}
      **Description:** #{custom_role.description || 'None'}
      **Permissions:**
      #{permissions_list.presence || '  No permissions assigned'}
    DETAILS
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
