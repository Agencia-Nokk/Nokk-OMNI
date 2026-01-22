# frozen_string_literal: true

module Captain::Tools::Concerns::JsonHelpers
  extend ActiveSupport::Concern

  private

  def parse_json_param(value, param_name)
    return value if value.is_a?(Array)

    JSON.parse(value)
  rescue JSON::ParserError
    "Invalid JSON for #{param_name}. Please provide a valid JSON array."
  end
end
