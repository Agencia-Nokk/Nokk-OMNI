class Captain::Tools::Copilot::ListAuditLogsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::AuditHelpers

  def self.name
    'list_audit_logs'
  end

  description <<~DESC
    List audit logs for the account. Filter by resource type, action, or user.

    **Auditable Types:** Account, AccountUser, AutomationRule, Conversation, Inbox, InboxMember, Macro, Team, TeamMember, User, Webhook, SlaPolicy

    **Actions:** create, update, destroy
  DESC

  param :auditable_type, type: :string, desc: 'Filter by resource type (e.g., "User", "Inbox")', required: false
  param :action, type: :string, desc: 'Filter by action (create, update, destroy)', required: false
  param :username, type: :string, desc: 'Filter by username/email', required: false
  param :limit, type: :number, desc: 'Number of records to return (default: 20, max: 100)', required: false

  def execute(auditable_type: nil, action: nil, username: nil, limit: nil)
    audits = build_query(auditable_type, action, username, limit)
    return 'No audit logs found matching the criteria' if audits.empty?

    {
      'content' => "Found #{audits.size} audit log(s):",
      'entities' => audits.map { |audit| format_audit_log_entity(audit) }
    }
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def build_query(auditable_type, action, username, limit)
    query = account_audits_scope.order(created_at: :desc)
    query = apply_filters(query, auditable_type, action, username)
    query.limit(calculate_limit(limit))
  end

  def apply_filters(query, auditable_type, action, username)
    query = query.where(auditable_type: auditable_type) if auditable_type.present?
    query = query.where(action: action.downcase) if action.present?
    query = query.where('username ILIKE ?', "%#{username}%") if username.present?
    query
  end

  def calculate_limit(limit)
    requested = limit.to_i
    requested.positive? ? [requested, 100].min : 20
  end
end
