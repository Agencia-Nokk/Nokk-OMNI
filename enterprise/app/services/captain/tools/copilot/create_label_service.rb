class Captain::Tools::Copilot::CreateLabelService < Captain::Tools::BaseTool
  def self.name
    'create_label'
  end

  description <<~DESC
    Create a new label in the account. Labels are used to categorize and organize conversations.

    **Parameters:**
    - title: Required. Label name (lowercase, alphanumeric, hyphens, underscores only)
    - color: Optional. Hex color code (default: #7a4aff)
    - description: Optional. Description of the label
    - show_on_sidebar: Optional. Whether to show on sidebar (default: false)
  DESC

  param :title, type: :string, desc: 'Label title (lowercase, alphanumeric, hyphens, underscores)'
  param :color, type: :string, desc: 'Hex color code (e.g., #ff0000)', required: false
  param :description, type: :string, desc: 'Label description', required: false
  param :show_on_sidebar, type: :boolean, desc: 'Show on sidebar', required: false

  def execute(title:, color: nil, description: nil, show_on_sidebar: nil)
    return 'Label title is required' if title.blank?

    attrs = { title: title.downcase.strip }
    attrs[:color] = color if color.present?
    attrs[:description] = description if description.present?
    attrs[:show_on_sidebar] = show_on_sidebar unless show_on_sidebar.nil?

    label = @assistant.account.labels.create!(attrs)

    {
      'content' => "Label '#{label.title}' created successfully",
      'entities' => [format_label_entity(label)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create label: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
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
