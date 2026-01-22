# frozen_string_literal: true

module Captain::Tools::Concerns::SlaHelpers
  extend ActiveSupport::Concern

  private

  def format_sla_policy_entity(sla_policy)
    {
      'type' => 'sla_policy',
      'id' => sla_policy.id,
      'name' => sla_policy.name,
      'description' => sla_policy.description,
      'first_response_time_threshold' => sla_policy.first_response_time_threshold,
      'next_response_time_threshold' => sla_policy.next_response_time_threshold,
      'resolution_time_threshold' => sla_policy.resolution_time_threshold,
      'only_during_business_hours' => sla_policy.only_during_business_hours
    }
  end

  def find_sla_policy(sla_policy_id: nil, name: nil)
    if sla_policy_id
      @assistant.account.sla_policies.find_by(id: sla_policy_id)
    elsif name
      @assistant.account.sla_policies.find_by('LOWER(name) = ?', name.downcase)
    end
  end

  def format_threshold(seconds)
    return 'Not set' unless seconds

    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    parts = []
    parts << "#{hours}h" if hours.positive?
    parts << "#{minutes}m" if minutes.positive?
    parts.empty? ? "#{seconds.to_i}s" : parts.join(' ')
  end
end
