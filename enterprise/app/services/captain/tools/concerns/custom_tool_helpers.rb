# frozen_string_literal: true

module Captain::Tools::Concerns::CustomToolHelpers
  extend ActiveSupport::Concern

  REQUIRED_PARAM_FIELDS = %w[name type description].freeze

  private

  def format_custom_tool_entity(tool)
    {
      'type' => 'custom_tool',
      'id' => tool.id,
      'slug' => tool.slug,
      'name' => tool.title,
      'description' => tool.description.to_s.truncate(100),
      'http_method' => tool.http_method,
      'enabled' => tool.enabled
    }
  end

  def format_custom_tool_full_entity(tool)
    {
      'type' => 'custom_tool',
      'id' => tool.id,
      'slug' => tool.slug,
      'name' => tool.title,
      'description' => tool.description,
      'endpoint_url' => tool.endpoint_url,
      'http_method' => tool.http_method,
      'auth_type' => tool.auth_type,
      'auth_config' => sanitize_auth_config(tool.auth_config),
      'param_schema' => tool.param_schema,
      'request_template' => tool.request_template,
      'response_template' => tool.response_template,
      'enabled' => tool.enabled,
      'created_at' => tool.created_at.iso8601,
      'updated_at' => tool.updated_at.iso8601
    }
  end

  def find_custom_tool(tool_id: nil, slug: nil, title: nil)
    scope = custom_tools_scope

    return scope.find_by(id: tool_id) if tool_id.present?
    return scope.find_by(slug: slug) if slug.present?
    return scope.find_by('LOWER(title) = ?', title.downcase.strip) if title.present?

    nil
  end

  def custom_tools_scope
    @assistant.account.captain_custom_tools
  end

  def sanitize_auth_config(auth_config)
    return {} if auth_config.blank?

    config = auth_config.dup
    config['token'] = '[REDACTED]' if config['token'].present?
    config['password'] = '[REDACTED]' if config['password'].present?
    config['key'] = '[REDACTED]' if config['key'].present?
    config
  end

  def validate_param_schema(schema)
    return nil if schema.blank?
    return 'param_schema must be an array' unless schema.is_a?(Array)

    schema.each_with_index do |param, index|
      return "param_schema[#{index}] must be an object" unless param.is_a?(Hash)

      missing = REQUIRED_PARAM_FIELDS - param.keys.map(&:to_s)
      return "param_schema[#{index}] missing: #{missing.join(', ')}" if missing.any?
    end
    nil
  end

  def validate_auth_config(auth_type, auth_config)
    return nil if auth_type == 'none'
    return 'auth_config is required for this auth_type' if auth_config.blank?

    case auth_type
    when 'bearer'
      validate_bearer_config(auth_config)
    when 'basic'
      validate_basic_config(auth_config)
    when 'api_key'
      validate_api_key_config(auth_config)
    else
      "Invalid auth_type: #{auth_type}"
    end
  end

  def validate_bearer_config(config)
    'Bearer auth requires token' if config['token'].blank?
  end

  def validate_basic_config(config)
    return 'Basic auth requires username' if config['username'].blank?

    'Basic auth requires password' if config['password'].blank?
  end

  def validate_api_key_config(config)
    return 'API key auth requires key' if config['key'].blank?
    return 'API key auth requires location (header or query)' if config['location'].blank?

    'API key auth requires name' if config['name'].blank?
  end

  def safe_parse_json(value, param_name)
    return value if value.is_a?(Array) || value.is_a?(Hash)
    return nil if value.blank?

    JSON.parse(value)
  rescue JSON::ParserError
    "Invalid JSON for #{param_name}"
  end
end
