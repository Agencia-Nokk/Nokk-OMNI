class Captain::Tools::Copilot::ListMacrosService < Captain::Tools::BaseTool
  def self.name
    'list_macros'
  end

  description <<~DESC
    List available macros in the account. Returns macro ID, name, visibility, and action summary.
    Use this to find macros before getting details or updating them.
  DESC

  param :name, type: :string, desc: 'Filter by name (partial match)', required: false

  def execute(name: nil)
    macros = @assistant.account.macros
    macros = macros.where('LOWER(name) ILIKE ?', "%#{name.downcase}%") if name.present?
    macros = macros.limit(50).order(:name)

    return { 'content' => 'No macros found', 'entities' => [] } unless macros.exists?

    {
      'content' => "Found #{macros.count} macro(s):",
      'entities' => macros.map { |m| format_macro_entity(m) }
    }
  end

  def active?
    true
  end

  private

  def format_macro_entity(macro)
    {
      'type' => 'macro',
      'id' => macro.id,
      'name' => macro.name,
      'visibility' => macro.visibility,
      'actions_count' => macro.actions.size
    }
  end
end
