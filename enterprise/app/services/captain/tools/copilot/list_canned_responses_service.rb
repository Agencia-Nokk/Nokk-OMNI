class Captain::Tools::Copilot::ListCannedResponsesService < Captain::Tools::BaseTool
  def self.name
    'list_canned_responses'
  end

  description 'List all canned responses (quick replies) available in the account'

  def execute
    canned_responses = @assistant.account.canned_responses
    return 'No canned responses found in this account' if canned_responses.empty?

    {
      'content' => "Found #{canned_responses.count} canned response(s):",
      'entities' => canned_responses.map { |cr| format_canned_response_entity(cr) }
    }
  end

  def active?
    user_has_permission('administrator') || user_has_permission('agent')
  end

  private

  def format_canned_response_entity(canned_response)
    {
      'type' => 'canned_response',
      'id' => canned_response.id,
      'name' => canned_response.short_code,
      'content' => canned_response.content.truncate(100)
    }
  end
end
