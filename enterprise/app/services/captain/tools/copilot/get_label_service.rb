class Captain::Tools::Copilot::GetLabelService < Captain::Tools::BaseTool
  def self.name
    'get_label'
  end

  description 'Get details of a specific label by ID or title'
  param :label_id, type: :number, desc: 'ID of the label', required: false
  param :title, type: :string, desc: 'Title of the label', required: false

  def execute(label_id: nil, title: nil)
    label = find_label(label_id, title)
    return 'Label not found' unless label

    {
      'content' => 'Label details:',
      'entities' => [format_label_entity(label)]
    }
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def find_label(label_id, title)
    if label_id
      @assistant.account.labels.find_by(id: label_id)
    elsif title
      @assistant.account.labels.find_by(title: title.downcase)
    end
  end

  def format_label_entity(label)
    {
      'type' => 'label',
      'id' => label.id,
      'name' => label.title,
      'color' => label.color,
      'description' => label.description,
      'show_on_sidebar' => label.show_on_sidebar
    }
  end
end
