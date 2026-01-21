class Captain::Tools::Copilot::DeleteMacroService < Captain::Tools::BaseTool
  def self.name
    'delete_macro'
  end

  description <<~DESC
    Delete an existing macro permanently.

    **Warning:** This action cannot be undone.

    First use list_macros to find the macro ID you want to delete.
  DESC

  param :macro_id, type: :integer, desc: 'ID of the macro to delete', required: true

  def execute(macro_id:)
    macro = @assistant.account.macros.find_by(id: macro_id)
    return "Macro with ID #{macro_id} not found" if macro.blank?

    macro_name = macro.name
    macro.destroy!

    Rails.logger.info do
      "#{self.class.name}: delete_macro #{macro_id} (#{macro_name}) for assistant #{@assistant&.id}"
    end

    "Macro '#{macro_name}' (ID: #{macro_id}) deleted successfully"
  end

  def active?
    true
  end
end
