# frozen_string_literal: true

module Captain::Tools::Concerns::AutomationRuleHelpers
  extend ActiveSupport::Concern

  include Captain::Tools::Concerns::AutomationRuleValidators
  include Captain::Tools::Concerns::AutomationRuleFormatters
  include Captain::Tools::Concerns::AutomationRuleResolvers

  private

  def parse_json_param(value, param_name)
    return value if value.is_a?(Array)

    JSON.parse(value)
  rescue JSON::ParserError
    "Invalid JSON for #{param_name}. Please provide a valid JSON array."
  end

  def normalize_conditions(conditions)
    return 'Conditions must be an array' unless conditions.is_a?(Array)
    return 'At least one condition is required' if conditions.empty?

    valid_attrs = valid_condition_attributes
    normalized = []

    conditions.each_with_index do |condition, index|
      result = validate_and_normalize_condition(condition, index, valid_attrs)
      return result if result.is_a?(String)

      normalized << result
    end

    normalized
  end

  def normalize_actions(actions, resolve_params: false)
    return 'Actions must be an array' unless actions.is_a?(Array)
    return 'At least one action is required' if actions.empty?

    valid_actions = AutomationRule.new(account: account_for_validation).actions_attributes
    normalized = []

    actions.each do |action|
      result = validate_and_normalize_action(action, valid_actions, resolve_params)
      return result if result.is_a?(String)

      normalized << result
    end

    normalized
  end

  def account_for_validation
    @assistant.account
  end

  def valid_condition_attributes
    @valid_condition_attributes ||= begin
      rule = AutomationRule.new(account: account_for_validation)
      custom_attrs = account_for_validation.custom_attribute_definitions.pluck(:attribute_key)
      (rule.conditions_attributes + custom_attrs).uniq
    end
  end

  def validate_and_normalize_condition(condition, index, valid_attrs)
    condition = condition.with_indifferent_access
    attribute_key = condition[:attribute_key]
    filter_operator = condition[:filter_operator]
    values = condition[:values]
    query_operator = condition[:query_operator]

    error = validate_condition_fields(attribute_key, filter_operator, query_operator, index, valid_attrs)
    return error if error

    build_normalized_condition(attribute_key, filter_operator, values, query_operator, index)
  end

  def validate_and_normalize_action(action, valid_actions, resolve_params)
    action = action.with_indifferent_access
    action_name = action[:action_name]

    return "Invalid action '#{action_name}'. Valid: #{valid_actions.join(', ')}" unless valid_actions.include?(action_name)

    action_params = resolve_params ? resolve_action_params(action_name, action[:action_params]) : Array(action[:action_params])
    return action_params if action_params.is_a?(String) && action_params.start_with?('Error:')

    { 'action_name' => action_name, 'action_params' => action_params }
  end

  def build_normalized_condition(attribute_key, filter_operator, values, query_operator, index)
    {
      'attribute_key' => attribute_key,
      'filter_operator' => filter_operator,
      'values' => Array(values || []),
      'query_operator' => index.zero? ? nil : query_operator&.upcase
    }
  end
end
