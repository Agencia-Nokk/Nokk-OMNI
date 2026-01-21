class Captain::Tools::Copilot::ListLabelsService < Captain::Tools::BaseTool
  def self.name
    'list_labels'
  end

  description 'List all labels available in the account with their details'

  def execute
    labels = @assistant.account.labels
    return 'No labels found in this account' if labels.empty?

    {
      'content' => "Found #{labels.count} label(s):",
      'entities' => labels.map { |label| format_label_entity(label) }
    }
  end

  def active?
    user_has_permission('administrator') || user_has_permission('agent')
  end

  private

  def format_label_entity(label)
    {
      'type' => 'label',
      'id' => label.id,
      'name' => label.title,
      'color' => label.color,
      'description' => label.description
    }
  end
end
