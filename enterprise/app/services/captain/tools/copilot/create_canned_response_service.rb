class Captain::Tools::Copilot::CreateCannedResponseService < Captain::Tools::BaseTool
  def self.name
    'create_canned_response'
  end

  description <<~DESC
    Create a new canned response (quick reply) in the account. Canned responses allow agents to quickly insert pre-written messages using short codes.

    **When to use:** Use this tool when you need to create reusable message templates for common responses. For example: greetings, thank you messages, FAQ answers, or escalation notices.

    **Complete Example:**
    To create a greeting response with personalization:
    {
      "short_code": "greeting",
      "content": "Hello {{ contact.name }}, thank you for contacting us! How can I help you today?"
    }

    **How to Use:** Agents type /short_code in the message box to insert the response.

    **Available Variables:**
    - {{ contact.name }} - Customer's name
    - {{ contact.email }} - Customer's email
    - {{ contact.phone_number }} - Customer's phone
    - {{ conversation.id }} - Conversation ID
    - {{ agent.name }} - Agent's name

    **Common Use Cases:**
    1. Greeting: short_code="hi", content="Hello {{ contact.name }}, how can I help you today?"
    2. Thank You: short_code="thanks", content="Thank you for contacting us. Have a great day!"
    3. Hold Message: short_code="hold", content="Please hold while I check this for you."
    4. Escalation: short_code="escalate", content="I'm transferring you to a specialist who can better assist."
    5. Business Hours: short_code="hours", content="Our support hours are Mon-Fri 9AM-6PM. We'll respond soon!"
    6. Refund Info: short_code="refund", content="Refunds are processed within 5-7 business days."

    For more details: https://www.chatwoot.com/docs/product/features/canned-responses
  DESC

  param :short_code, type: :string, desc: 'Short code trigger (e.g., "greeting")'
  param :content, type: :string, desc: 'Message content (can include variables like {{ contact.name }})'

  def execute(short_code:, content:)
    validation = validate_params(short_code, content)
    return validation if validation

    create_canned_response(short_code, content)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create canned response: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def validate_params(short_code, content)
    return 'Short code is required' if short_code.blank?
    return 'Content is required' if content.blank?

    check_existing(short_code)
  end

  def check_existing(short_code)
    existing = @assistant.account.canned_responses.find_by(short_code: short_code)
    return nil if existing.blank?

    {
      'content' => "A canned response with short code '#{short_code}' already exists (ID: #{existing.id}). " \
                   'Would you like to update it using update_canned_response tool, or create a new one with a different short code?',
      'entities' => [format_canned_response_entity(existing)]
    }
  end

  def create_canned_response(short_code, content)
    canned_response = @assistant.account.canned_responses.create!(short_code: short_code.strip, content: content)

    {
      'content' => "Canned response '#{canned_response.short_code}' created successfully. " \
                   "Agents can now use /#{canned_response.short_code} to insert this response.",
      'entities' => [format_canned_response_entity(canned_response)]
    }
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
