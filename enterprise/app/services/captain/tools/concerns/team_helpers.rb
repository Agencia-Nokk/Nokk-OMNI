# frozen_string_literal: true

module Captain::Tools::Concerns::TeamHelpers
  extend ActiveSupport::Concern

  private

  def format_team_entity(team)
    {
      'type' => 'team',
      'id' => team.id,
      'name' => team.name,
      'description' => team.description,
      'members_count' => team.members.count,
      'allow_auto_assign' => team.allow_auto_assign
    }
  end

  def find_team_by_id_or_name(team_id: nil, name: nil)
    if team_id
      @assistant.account.teams.find_by(id: team_id)
    elsif name
      @assistant.account.teams.find_by(name: name.downcase)
    end
  end

  def parse_member_ids(member_ids)
    return [] if member_ids.blank?

    if member_ids.is_a?(Array)
      member_ids.map(&:to_i)
    else
      JSON.parse(member_ids).map(&:to_i)
    end
  rescue JSON::ParserError
    []
  end
end
