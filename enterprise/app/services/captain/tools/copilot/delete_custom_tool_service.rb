# frozen_string_literal: true

class Captain::Tools::Copilot::DeleteCustomToolService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::CustomToolHelpers

  def self.name
    'delete_custom_tool'
  end

  def name
    'delete_custom_tool'
  end

  description <<~DESC
    Delete a custom HTTP tool from the account. This action cannot be undone.

    **When to use:**
    - To remove a tool that is no longer needed
    - To clean up unused integrations
    - Before recreating a tool with the same name

    **Warning:** This permanently deletes the tool configuration.
  DESC

  param :tool_id, type: :number, desc: 'ID of the tool to delete'

  def execute(tool_id:)
    return 'Tool ID is required' if tool_id.blank?

    tool = find_custom_tool(tool_id: tool_id)
    return tool_not_found_message(tool_id) unless tool

    delete_tool(tool)
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def delete_tool(tool)
    title = tool.title
    tool_id = tool.id

    tool.destroy!

    format_success_message(title, tool_id)
  end

  def format_success_message(title, tool_id)
    "Custom tool '#{title}' (ID: #{tool_id}) has been deleted successfully."
  end

  def tool_not_found_message(tool_id)
    "Custom tool with ID #{tool_id} not found"
  end
end
