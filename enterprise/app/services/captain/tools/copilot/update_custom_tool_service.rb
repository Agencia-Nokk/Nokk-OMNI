# frozen_string_literal: true

class Captain::Tools::Copilot::UpdateCustomToolService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::CustomToolHelpers
  include Captain::Tools::Concerns::JsonHelpers

  VALID_HTTP_METHODS = %w[GET POST].freeze
  VALID_AUTH_TYPES = %w[none bearer basic api_key].freeze
  UPDATABLE_FIELDS = %i[
    title description endpoint_url http_method param_schema
    auth_type auth_config request_template response_template enabled
  ].freeze

  def self.name
    'update_custom_tool'
  end

  def name
    'update_custom_tool'
  end

  description <<~DESC
    Update an existing custom HTTP tool. Only provide the fields you want to change.

    **When to use:**
    - To modify tool configuration
    - To enable/disable a tool
    - To fix endpoint or parameters

    **Required:** tool_id
    **Optional:** All other fields (only changed fields need to be provided)
  DESC

  param :tool_id, type: :number, desc: 'ID of the tool to update'
  param :title, type: :string, desc: 'New tool name', required: false
  param :description, type: :string, desc: 'New description', required: false
  param :endpoint_url, type: :string, desc: 'New endpoint URL', required: false
  param :http_method, type: :string, desc: 'GET or POST', required: false
  param :param_schema, type: :string, desc: 'JSON array of parameters', required: false
  param :auth_type, type: :string, desc: 'none, bearer, basic, api_key', required: false
  param :auth_config, type: :string, desc: 'JSON auth configuration', required: false
  param :request_template, type: :string, desc: 'Liquid template for request', required: false
  param :response_template, type: :string, desc: 'Liquid template for response', required: false
  param :enabled, type: :boolean, desc: 'Enable or disable the tool', required: false

  def execute(tool_id:, **options)
    return 'Tool ID is required' if tool_id.blank?

    tool = find_custom_tool(tool_id: tool_id)
    return tool_not_found_message(tool_id) unless tool

    attributes = build_update_attributes(options)
    return attributes if attributes.is_a?(String)
    return 'No changes provided' if attributes.empty?

    validation = validate_attributes(attributes)
    return validation if validation.is_a?(String)

    update_tool(tool, attributes)
  rescue ActiveRecord::RecordInvalid => e
    format_update_error(e)
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def build_update_attributes(options)
    attributes = {}

    UPDATABLE_FIELDS.each do |field|
      next unless options.key?(field) && !options[field].nil?

      value = process_field_value(field, options[field])
      return value if value.is_a?(String) && value.start_with?('Invalid')

      attributes[field] = value
    end

    attributes
  end

  def process_field_value(field, value)
    case field
    when :param_schema
      parse_json_field(value, 'param_schema')
    when :auth_config
      parse_json_field(value, 'auth_config')
    when :http_method
      value.to_s.upcase
    else
      value
    end
  end

  def parse_json_field(value, field_name)
    result = safe_parse_json(value, field_name)
    return result if result.is_a?(String)

    result
  end

  def validate_attributes(attributes)
    validate_http_method(attributes[:http_method]) ||
      validate_auth_type(attributes[:auth_type]) ||
      validate_param_schema(attributes[:param_schema]) ||
      validate_auth_config_if_present(attributes)
  end

  def validate_http_method(method)
    return nil if method.blank?
    return nil if VALID_HTTP_METHODS.include?(method)

    "Invalid http_method: #{method}. Valid: #{VALID_HTTP_METHODS.join(', ')}"
  end

  def validate_auth_type(auth_type)
    return nil if auth_type.blank?
    return nil if VALID_AUTH_TYPES.include?(auth_type)

    "Invalid auth_type: #{auth_type}. Valid: #{VALID_AUTH_TYPES.join(', ')}"
  end

  def validate_auth_config_if_present(attributes)
    return nil unless attributes[:auth_type].present? && attributes[:auth_config].present?

    validate_auth_config(attributes[:auth_type], attributes[:auth_config])
  end

  def update_tool(tool, attributes)
    tool.update!(attributes)
    format_success_response(tool, attributes.keys)
  end

  def format_success_response(tool, updated_fields)
    {
      'content' => success_message(tool, updated_fields),
      'entities' => [format_custom_tool_entity(tool)]
    }
  end

  def success_message(tool, updated_fields)
    <<~MSG
      Custom tool '#{tool.title}' updated successfully!

      **Updated fields:** #{updated_fields.map(&:to_s).join(', ')}
      **Status:** #{tool.enabled ? 'Enabled' : 'Disabled'}
    MSG
  end

  def tool_not_found_message(tool_id)
    "Custom tool with ID #{tool_id} not found"
  end

  def format_update_error(error)
    "Failed to update custom tool: #{error.record.errors.full_messages.join(', ')}"
  end
end
