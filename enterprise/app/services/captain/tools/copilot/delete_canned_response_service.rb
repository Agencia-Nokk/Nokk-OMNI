class Captain::Tools::Copilot::DeleteCannedResponseService < Captain::Tools::BaseTool
  def self.name
    'delete_canned_response'
  end

  description 'Delete a canned response from the account.'

  param :canned_response_id, type: :number, desc: 'ID of the canned response to delete'

  def execute(canned_response_id:)
    canned_response = @assistant.account.canned_responses.find_by(id: canned_response_id)
    return 'Canned response not found' unless canned_response

    short_code = canned_response.short_code
    canned_response.destroy!

    "Canned response '#{short_code}' deleted successfully"
  end

  def active?
    user_has_permission('administrator')
  end
end
