class Captain::Tools::Copilot::CreateCannedResponseService < Captain::Tools::BaseTool
  def self.name
    'create_canned_response'
  end

  description <<~DESC
    Create a new canned response (quick reply) in the account. Canned responses allow agents to quickly insert pre-written messages using short codes.

    **Parameters:**
    - short_code: Required. The trigger code (e.g., "greeting", "thanks"). Agents type /short_code to insert.
    - content: Required. The message content. Can include variables like {{ contact.name }}.

    **Examples:**
    - short_code: "greeting", content: "Hello {{ contact.name }}, how can I help you today?"
    - short_code: "closing", content: "Thank you for contacting us. Have a great day!"
  DESC

  param :short_code, type: :string, desc: 'Short code trigger (e.g., "greeting")'
  param :content, type: :string, desc: 'Message content (can include variables like {{ contact.name }})'

  def execute(short_code:, content:)
    return 'Short code is required' if short_code.blank?
    return 'Content is required' if content.blank?

    existing = @assistant.account.canned_responses.find_by(short_code: short_code)
    if existing.present?
      return {
        'content' => "A canned response with short code '#{short_code}' already exists (ID: #{existing.id}). " \
                     'Would you like to update it using update_canned_response tool, or create a new one with a different short code?',
        'entities' => [format_canned_response_entity(existing)]
      }
    end

    canned_response = @assistant.account.canned_responses.create!(
      short_code: short_code.strip,
      content: content
    )

    {
      'content' => "Canned response '#{canned_response.short_code}' created successfully. Agents can now use /#{canned_response.short_code} to insert this response.",
      'entities' => [format_canned_response_entity(canned_response)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create canned response: #{e.message}"
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
