# frozen_string_literal: true

class Captain::Tools::Copilot::CreateCustomToolService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::CustomToolHelpers
  include Captain::Tools::Concerns::JsonHelpers

  VALID_HTTP_METHODS = %w[GET POST].freeze
  VALID_AUTH_TYPES = %w[none bearer basic api_key].freeze

  def self.name
    'create_custom_tool'
  end

  def name
    'create_custom_tool'
  end

  description <<~DESC
    Create a new custom HTTP tool that can be used by the AI assistant to call external APIs.

    **When to use:**
    - After analyzing API documentation with analyze_api_spec
    - When you have all the necessary information about an API endpoint

    **Required fields:**
    - title: Descriptive name (e.g., "ViaCEP Address Lookup")
    - description: What the tool does (helps AI know when to use it)
    - endpoint_url: URL with Liquid variables (e.g., "https://api.com/{{ id }}")

    **Optional fields:**
    - http_method: GET (default) or POST
    - param_schema: JSON array of parameters
    - auth_type: none (default), bearer, basic, api_key
    - auth_config: Authentication configuration
    - request_template: Liquid template for POST body
    - response_template: Liquid template to format response

    **Example param_schema:**
    [{"name": "cep", "type": "string", "description": "CEP code", "required": true}]
  DESC

  param :title, type: :string, desc: 'Tool name (e.g., "ViaCEP Address Lookup")'
  param :description, type: :string, desc: 'What the tool does'
  param :endpoint_url, type: :string, desc: 'API endpoint URL with Liquid variables'
  param :http_method, type: :string, desc: 'GET or POST (default: GET)', required: false
  param :param_schema, type: :string, desc: 'JSON array of parameters', required: false
  param :auth_type, type: :string, desc: 'none, bearer, basic, api_key', required: false
  param :auth_config, type: :string, desc: 'JSON auth configuration', required: false
  param :request_template, type: :string, desc: 'Liquid template for request body', required: false
  param :response_template, type: :string, desc: 'Liquid template for response', required: false
  param :enabled, type: :boolean, desc: 'Enable tool (default: true)', required: false

  def execute(title:, description:, endpoint_url:, **options)
    validation = validate_required_params(title, description, endpoint_url)
    return validation if validation.is_a?(String)

    parsed_options = parse_json_options(options)
    return parsed_options if parsed_options.is_a?(String)

    validation = validate_options(parsed_options)
    return validation if validation.is_a?(String)

    existing = check_existing_tool(title)
    return existing if existing.is_a?(Hash)

    create_tool(title, description, endpoint_url, parsed_options)
  rescue ActiveRecord::RecordInvalid => e
    format_creation_error(e)
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def validate_required_params(title, description, endpoint_url)
    return 'Title is required' if title.blank?
    return 'Description is required' if description.blank?
    return 'Endpoint URL is required' if endpoint_url.blank?

    nil
  end

  def parse_json_options(options)
    parsed = options.dup

    if options[:param_schema].present?
      result = safe_parse_json(options[:param_schema], 'param_schema')
      return result if result.is_a?(String)

      parsed[:param_schema] = result
    end

    if options[:auth_config].present?
      result = safe_parse_json(options[:auth_config], 'auth_config')
      return result if result.is_a?(String)

      parsed[:auth_config] = result
    end

    parsed
  end

  def validate_options(options)
    validate_http_method(options[:http_method]) ||
      validate_auth_type(options[:auth_type]) ||
      validate_param_schema(options[:param_schema]) ||
      validate_auth_config(options[:auth_type] || 'none', options[:auth_config])
  end

  def validate_http_method(method)
    return nil if method.blank?
    return nil if VALID_HTTP_METHODS.include?(method.to_s.upcase)

    "Invalid http_method: #{method}. Valid: #{VALID_HTTP_METHODS.join(', ')}"
  end

  def validate_auth_type(auth_type)
    return nil if auth_type.blank?
    return nil if VALID_AUTH_TYPES.include?(auth_type.to_s)

    "Invalid auth_type: #{auth_type}. Valid: #{VALID_AUTH_TYPES.join(', ')}"
  end

  def check_existing_tool(title)
    existing = custom_tools_scope.find_by('LOWER(title) = ?', title.downcase.strip)
    return nil unless existing

    {
      'content' => existing_tool_message(existing),
      'entities' => [format_custom_tool_entity(existing)]
    }
  end

  def existing_tool_message(tool)
    <<~MSG
      A tool named '#{tool.title}' already exists (ID: #{tool.id}).

      Options:
      1. Use `update_custom_tool` to modify the existing tool
      2. Choose a different name for the new tool
      3. Use `delete_custom_tool` to remove the existing one first
    MSG
  end

  def create_tool(title, description, endpoint_url, options)
    tool = custom_tools_scope.create!(
      build_tool_attributes(title, description, endpoint_url, options)
    )

    format_success_response(tool)
  end

  def build_tool_attributes(title, description, endpoint_url, options)
    {
      title: title.strip,
      description: description,
      endpoint_url: endpoint_url,
      http_method: (options[:http_method] || 'GET').upcase,
      param_schema: options[:param_schema] || [],
      auth_type: options[:auth_type] || 'none',
      auth_config: options[:auth_config] || {},
      request_template: options[:request_template],
      response_template: options[:response_template],
      enabled: options.fetch(:enabled, true)
    }
  end

  def format_success_response(tool)
    {
      'content' => success_message(tool),
      'entities' => [format_custom_tool_entity(tool)]
    }
  end

  def success_message(tool)
    <<~MSG
      Custom tool '#{tool.title}' created successfully!

      **ID:** #{tool.id}
      **Slug:** #{tool.slug}
      **Status:** #{tool.enabled ? 'Enabled' : 'Disabled'}

      The tool is now available for the AI assistant to use.
    MSG
  end

  def format_creation_error(error)
    "Failed to create custom tool: #{error.record.errors.full_messages.join(', ')}"
  end
end
