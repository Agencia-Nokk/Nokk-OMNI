class Captain::Tools::Copilot::DeleteCustomRoleService < Captain::Tools::BaseTool
  def self.name
    'delete_custom_role'
  end

  description <<~DESC
    Delete a custom role from the account.
    Note: Agents assigned to this role will have their custom_role set to null.
  DESC

  param :custom_role_id, type: :integer, desc: 'ID of the custom role to delete'

  def execute(custom_role_id:)
    custom_role = @assistant.account.custom_roles.find_by(id: custom_role_id)
    return 'Custom role not found' unless custom_role

    name = custom_role.name
    affected_agents = custom_role.account_users.count
    custom_role.destroy!

    message = "Custom role '#{name}' deleted successfully"
    message += ". #{affected_agents} agent(s) had their custom role removed." if affected_agents.positive?
    message
  end

  def active?
    user_has_permission('administrator')
  end
end
