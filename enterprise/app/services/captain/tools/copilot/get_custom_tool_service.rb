# frozen_string_literal: true

class Captain::Tools::Copilot::GetCustomToolService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::CustomToolHelpers

  def self.name
    'get_custom_tool'
  end

  def name
    'get_custom_tool'
  end

  description <<~DESC
    Get detailed information about a specific custom tool. Returns all
    configuration including endpoint, parameters, authentication, and templates.

    **When to use:**
    - To see full details of a tool before updating
    - To understand how a tool is configured
    - To verify tool configuration

    **Search by:** ID, slug, or title (provide at least one)
  DESC

  param :tool_id, type: :number, desc: 'Tool ID', required: false
  param :slug, type: :string, desc: 'Tool slug (e.g., "custom_viacep")', required: false
  param :title, type: :string, desc: 'Tool title (case insensitive)', required: false

  def execute(tool_id: nil, slug: nil, title: nil)
    return missing_identifier_message if all_blank?(tool_id, slug, title)

    tool = find_custom_tool(tool_id: tool_id, slug: slug, title: title)
    return tool_not_found_message(tool_id, slug, title) unless tool

    format_tool_response(tool)
  end

  def active?
    user_has_permission('administrator') || user_has_permission('agent')
  end

  private

  def all_blank?(*values)
    values.all?(&:blank?)
  end

  def format_tool_response(tool)
    {
      'content' => build_tool_details(tool),
      'entities' => [format_custom_tool_full_entity(tool)]
    }
  end

  def build_tool_details(tool)
    <<~DETAILS
      ## Custom Tool: #{tool.title}

      **ID:** #{tool.id}
      **Slug:** #{tool.slug}
      **Status:** #{tool.enabled ? 'Enabled' : 'Disabled'}
      **Created:** #{tool.created_at.strftime('%Y-%m-%d %H:%M')}

      ### Endpoint
      - **URL:** `#{tool.endpoint_url}`
      - **Method:** #{tool.http_method}

      ### Authentication
      - **Type:** #{tool.auth_type}
      #{format_auth_info(tool)}

      ### Parameters
      #{format_params_info(tool)}

      ### Templates
      #{format_templates_info(tool)}

      ### Description
      #{tool.description || 'No description'}
    DETAILS
  end

  def format_auth_info(tool)
    return '' if tool.auth_type == 'none'

    config = sanitize_auth_config(tool.auth_config)
    "- **Config:** #{config.to_json}"
  end

  def format_params_info(tool)
    return '_No parameters defined_' if tool.param_schema.blank?

    tool.param_schema.map do |param|
      required = param['required'] ? '(required)' : '(optional)'
      "- **#{param['name']}** (#{param['type']}) #{required}: #{param['description']}"
    end.join("\n")
  end

  def format_templates_info(tool)
    templates = []
    templates << "- **Request:** `#{tool.request_template}`" if tool.request_template.present?
    templates << "- **Response:** `#{tool.response_template}`" if tool.response_template.present?

    templates.empty? ? '_No templates configured_' : templates.join("\n")
  end

  def missing_identifier_message
    'Please provide at least one of: tool_id, slug, or title'
  end

  def tool_not_found_message(tool_id, slug, title)
    identifier = [
      tool_id.present? ? "ID #{tool_id}" : nil,
      slug.present? ? "slug '#{slug}'" : nil,
      title.present? ? "title '#{title}'" : nil
    ].compact.join(' or ')

    "Custom tool not found with #{identifier}"
  end
end
