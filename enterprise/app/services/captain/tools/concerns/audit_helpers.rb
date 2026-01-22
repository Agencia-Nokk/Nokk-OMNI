# frozen_string_literal: true

module Captain::Tools::Concerns::AuditHelpers
  extend ActiveSupport::Concern

  AUDITABLE_TYPES = %w[
    Account AccountUser AutomationRule Conversation
    Inbox InboxMember Macro Team TeamMember User Webhook SlaPolicy
  ].freeze

  AUDIT_ACTIONS = %w[create update destroy].freeze

  private

  def format_audit_log_entity(audit)
    {
      'type' => 'audit_log',
      'id' => audit.id,
      'action' => audit.action,
      'auditable_type' => audit.auditable_type,
      'auditable_id' => audit.auditable_id,
      'username' => audit.username,
      'created_at' => audit.created_at&.iso8601
    }
  end

  def account_audits_scope
    Enterprise::AuditLog.where(associated_type: 'Account', associated_id: @assistant.account.id)
  end
end
