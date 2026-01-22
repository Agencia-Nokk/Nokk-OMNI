# frozen_string_literal: true

class Captain::Tools::Copilot::ListCustomToolsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::CustomToolHelpers

  def self.name
    'list_custom_tools'
  end

  def name
    'list_custom_tools'
  end

  description <<~DESC
    List all custom HTTP tools configured in the account. Custom tools are
    external API integrations that can be used by the AI assistant.

    **When to use:**
    - To see available custom tools
    - To find a tool to update or delete
    - To check if a tool already exists before creating

    **Returns:** List of tools with name, description, status, and endpoint info
  DESC

  param :enabled_only, type: :boolean, desc: 'Filter to show only enabled tools', required: false
  param :search, type: :string, desc: 'Search by title or description', required: false

  def execute(enabled_only: false, search: nil)
    tools = fetch_tools(enabled_only, search)
    format_tools_response(tools)
  end

  def active?
    user_has_permission('administrator') || user_has_permission('agent')
  end

  private

  def fetch_tools(enabled_only, search)
    scope = custom_tools_scope.order(created_at: :desc)
    scope = scope.enabled if enabled_only
    scope = apply_search_filter(scope, search) if search.present?
    scope
  end

  def apply_search_filter(scope, search)
    search_term = "%#{search.downcase}%"
    scope.where('LOWER(title) LIKE ? OR LOWER(description) LIKE ?', search_term, search_term)
  end

  def format_tools_response(tools)
    return no_tools_message if tools.empty?

    {
      'content' => build_tools_list_content(tools),
      'entities' => tools.map { |t| format_custom_tool_entity(t) }
    }
  end

  def build_tools_list_content(tools)
    enabled_count = tools.count(&:enabled)
    disabled_count = tools.count - enabled_count

    <<~CONTENT
      Found #{tools.count} custom tool(s) (#{enabled_count} enabled, #{disabled_count} disabled):

      #{format_tools_summary(tools)}

      Use `get_custom_tool` with a tool ID to see full details.
    CONTENT
  end

  def format_tools_summary(tools)
    tools.map do |tool|
      status = tool.enabled ? '✓' : '✗'
      "- [#{status}] **#{tool.title}** (ID: #{tool.id}) - #{tool.http_method} #{truncate_url(tool.endpoint_url)}"
    end.join("\n")
  end

  def truncate_url(url)
    return url if url.length <= 50

    "#{url[0, 47]}..."
  end

  def no_tools_message
    <<~MSG
      No custom tools found in this account.

      To create a new tool:
      1. Use `search_api_documentation` to find API docs (if needed)
      2. Use `read_api_documentation` to read the docs
      3. Use `analyze_api_spec` to extract tool parameters
      4. Use `create_custom_tool` to create the tool
    MSG
  end
end
