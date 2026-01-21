class Captain::Tools::Copilot::DeleteLabelService < Captain::Tools::BaseTool
  def self.name
    'delete_label'
  end

  description 'Delete a label from the account. This will remove the label from all conversations and contacts.'

  param :label_id, type: :number, desc: 'ID of the label to delete'

  def execute(label_id:)
    label = @assistant.account.labels.find_by(id: label_id)
    return 'Label not found' unless label

    title = label.title
    label.destroy!

    "Label '#{title}' deleted successfully"
  end

  def active?
    user_has_permission('administrator')
  end
end
