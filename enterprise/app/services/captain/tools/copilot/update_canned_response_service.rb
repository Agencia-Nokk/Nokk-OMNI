class Captain::Tools::Copilot::UpdateCannedResponseService < Captain::Tools::BaseTool
  def self.name
    'update_canned_response'
  end

  description 'Update an existing canned response. You can update the short code and/or content.'

  param :canned_response_id, type: :number, desc: 'ID of the canned response to update'
  param :short_code, type: :string, desc: 'New short code', required: false
  param :content, type: :string, desc: 'New content', required: false

  def execute(canned_response_id:, short_code: nil, content: nil)
    canned_response = @assistant.account.canned_responses.find_by(id: canned_response_id)
    return 'Canned response not found' unless canned_response

    attrs = {}
    attrs[:short_code] = short_code.strip if short_code.present?
    attrs[:content] = content if content.present?

    return 'No changes provided' if attrs.empty?

    canned_response.update!(attrs)

    {
      'content' => "Canned response '#{canned_response.short_code}' updated successfully",
      'entities' => [format_canned_response_entity(canned_response)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update canned response: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
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
