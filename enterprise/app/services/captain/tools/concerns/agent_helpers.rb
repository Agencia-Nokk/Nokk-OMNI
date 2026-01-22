# frozen_string_literal: true

module Captain::Tools::Concerns::AgentHelpers
  extend ActiveSupport::Concern

  VALID_ROLES = %w[agent administrator admin].freeze
  VALID_AVAILABILITIES = %w[online offline busy].freeze

  private

  def format_agent_entity(agent)
    account_user = find_account_user(agent)
    {
      'type' => 'agent',
      'id' => agent.id,
      'name' => agent.available_name || agent.name,
      'email' => agent.email,
      'role' => account_user&.role,
      'availability' => account_user&.availability
    }
  end

  def find_account_user(agent)
    agent.account_users.find { |au| au.account_id == @assistant.account.id }
  end

  def find_agent(agent_id)
    @assistant.account.users.includes(:account_users)
              .where(account_users: { role: [:agent, :administrator] })
              .find_by(id: agent_id)
  end

  def validate_role(role)
    return :agent if role.blank?

    role = role.to_s.downcase.strip
    return :agent if role == 'agent'
    return :administrator if %w[administrator admin].include?(role)

    nil
  end

  def validate_availability(availability)
    availability = availability.to_s.downcase.strip
    case availability
    when 'online' then :online
    when 'offline' then :offline
    when 'busy' then :busy
    end
  end
end
