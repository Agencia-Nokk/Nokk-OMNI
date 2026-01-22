class Captain::Tools::Copilot::CreateLabelService < Captain::Tools::BaseTool
  def self.name
    'create_label'
  end

  description <<~DESC
    Create a new label in the account. Labels are used to categorize and organize conversations for easy filtering and reporting.

    **When to use:** Use this tool when you need to categorize conversations by topic, priority, or status. For example: tagging support categories, marking VIP customers, or tracking issues.

    **Complete Example:**
    To create a "billing" label with a red color:
    {
      "title": "billing",
      "color": "#e53e3e",
      "description": "Payment and subscription issues",
      "show_on_sidebar": true
    }

    **Parameters:**
    - title: Label name (lowercase, alphanumeric, hyphens, underscores only)
    - color: Hex color code for visual identification
    - description: What this label represents
    - show_on_sidebar: Quick access from sidebar (useful for frequent labels)

    **Common Color Codes:**
    - Red: #e53e3e (urgent, billing issues)
    - Orange: #ed8936 (warning, follow-up needed)
    - Green: #48bb78 (resolved, positive feedback)
    - Blue: #4299e1 (technical, feature request)
    - Purple: #9f7aea (VIP, premium)
    - Gray: #a0aec0 (archived, low priority)

    **Common Use Cases:**
    1. Support Categories: "billing", "technical", "sales", "general"
    2. Priority Tags: "urgent", "high-priority", "follow-up"
    3. Customer Segments: "vip", "enterprise", "trial"
    4. Issue Types: "bug-report", "feature-request", "feedback"

    For more details: https://www.chatwoot.com/docs/product/features/labels
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
