# frozen_string_literal: true

module Captain::Tools::Concerns::AutomationRuleValidators
  extend ActiveSupport::Concern

  VALID_EVENTS = %w[conversation_created conversation_updated conversation_opened conversation_resolved message_created].freeze
  VALID_FILTER_OPERATORS = %w[equal_to not_equal_to contains does_not_contain is_present is_not_present starts_with].freeze
  VALID_QUERY_OPERATORS = %w[AND OR].freeze

  private

  def validate_condition_fields(attribute_key, filter_operator, query_operator, index, valid_attrs)
    validate_required_fields(attribute_key, filter_operator, index) ||
      validate_attribute_key(attribute_key, index, valid_attrs) ||
      validate_filter_operator(filter_operator, index) ||
      validate_query_operator(query_operator, index)
  end

  def validate_required_fields(attribute_key, filter_operator, index)
    return "Condition #{index + 1}: attribute_key is required" if attribute_key.blank?
    return "Condition #{index + 1}: filter_operator is required" if filter_operator.blank?

    nil
  end

  def validate_attribute_key(attribute_key, index, valid_attrs)
    return nil if valid_attrs.include?(attribute_key)

    "Condition #{index + 1}: Invalid attribute_key '#{attribute_key}'. Valid: #{valid_attrs.join(', ')}"
  end

  def validate_filter_operator(filter_operator, index)
    return nil if VALID_FILTER_OPERATORS.include?(filter_operator)

    "Condition #{index + 1}: Invalid filter_operator '#{filter_operator}'. Valid: #{VALID_FILTER_OPERATORS.join(', ')}"
  end

  def validate_query_operator(query_operator, index)
    return "Condition #{index + 1}: query_operator is required (AND or OR)" if index.positive? && query_operator.blank?

    if query_operator.present? && VALID_QUERY_OPERATORS.exclude?(query_operator.upcase)
      return "Condition #{index + 1}: query_operator must be 'AND' or 'OR'"
    end

    nil
  end
end
