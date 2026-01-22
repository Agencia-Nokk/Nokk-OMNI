class Captain::Tools::Copilot::UpdateLabelService < Captain::Tools::BaseTool
  def self.name
    'update_label'
  end

  description <<~DESC
    Update an existing label. You can update title, color, description, or sidebar visibility.
    Note: Changing title will update all conversations/contacts using this label.
  DESC

  param :label_id, type: :number, desc: 'ID of the label to update'
  param :title, type: :string, desc: 'New title for the label', required: false
  param :color, type: :string, desc: 'New hex color code', required: false
  param :description, type: :string, desc: 'New description', required: false
  param :show_on_sidebar, type: :boolean, desc: 'Show on sidebar', required: false

  def execute(label_id:, title: nil, color: nil, description: nil, show_on_sidebar: nil)
    label = @assistant.account.labels.find_by(id: label_id)
    return 'Label not found' unless label

    attrs = build_label_attrs(title, color, description, show_on_sidebar)
    return 'No changes provided' if attrs.empty?

    apply_label_update(label, attrs)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update label: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def build_label_attrs(title, color, description, show_on_sidebar)
    attrs = {}
    attrs[:title] = title.downcase.strip if title.present?
    attrs[:color] = color if color.present?
    attrs[:description] = description if description.present?
    attrs[:show_on_sidebar] = show_on_sidebar unless show_on_sidebar.nil?
    attrs
  end

  def apply_label_update(label, attrs)
    label.update!(attrs)

    {
      'content' => "Label '#{label.title}' updated successfully",
      'entities' => [format_label_entity(label)]
    }
  end

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
