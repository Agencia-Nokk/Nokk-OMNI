class Captain::Tools::Copilot::GetCannedResponseService < Captain::Tools::BaseTool
  def self.name
    'get_canned_response'
  end

  description 'Get details of a specific canned response by ID or short code'
  param :canned_response_id, type: :number, desc: 'ID of the canned response', required: false
  param :short_code, type: :string, desc: 'Short code of the canned response', required: false

  def execute(canned_response_id: nil, short_code: nil)
    canned_response = find_canned_response(canned_response_id, short_code)
    return 'Canned response not found' unless canned_response

    {
      'content' => "Canned response details:\n\n**Short code:** #{canned_response.short_code}\n**Content:**\n#{canned_response.content}",
      'entities' => [format_canned_response_entity(canned_response)]
    }
  end

  def active?
    user_has_permission('administrator') || user_has_permission('agent')
  end

  private

  def find_canned_response(canned_response_id, short_code)
    if canned_response_id
      @assistant.account.canned_responses.find_by(id: canned_response_id)
    elsif short_code
      @assistant.account.canned_responses.find_by(short_code: short_code)
    end
  end

  def format_canned_response_entity(canned_response)
    {
      'type' => 'canned_response',
      'id' => canned_response.id,
      'name' => canned_response.short_code,
      'content' => canned_response.content.truncate(100)
    }
  end
end
