class Captain::Tools::Copilot::GetAuditLogService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::AuditHelpers

  def self.name
    'get_audit_log'
  end

  description 'Get full details of a specific audit log entry including all changes made'

  param :audit_id, type: :number, desc: 'ID of the audit log entry'

  def execute(audit_id:)
    audit = account_audits_scope.find_by(id: audit_id)
    return "Audit log with ID #{audit_id} not found" unless audit

    {
      'content' => build_details(audit),
      'entities' => [format_audit_log_entity(audit)]
    }
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def build_details(audit)
    changes = format_changes(audit.audited_changes)

    <<~DETAILS.strip
      **Audit Log ##{audit.id}**
      **Action:** #{audit.action.capitalize}
      **Resource:** #{audit.auditable_type} ##{audit.auditable_id}
      **User:** #{audit.username || 'System'}
      **Date:** #{audit.created_at&.strftime('%Y-%m-%d %H:%M:%S')}
      **IP Address:** #{audit.remote_address || 'N/A'}

      **Changes:**
      #{changes}
    DETAILS
  end

  def format_changes(changes)
    return 'No changes recorded' if changes.blank?

    changes.map { |field, values| format_change_line(field, values) }.join("\n")
  end

  def format_change_line(field, values)
    if values.is_a?(Array)
      "  - #{field}: #{values[0].inspect} -> #{values[1].inspect}"
    else
      "  - #{field}: #{values.inspect}"
    end
  end
end
