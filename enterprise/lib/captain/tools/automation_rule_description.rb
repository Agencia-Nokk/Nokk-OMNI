# frozen_string_literal: true

module Captain::Tools::AutomationRuleDescription
  EVENTS_DESC = <<~DESC
    **Events (Triggers):**
    - conversation_created: Triggers when a new conversation is created
    - conversation_updated: Triggers when conversation properties change (status, assignee, etc.)
    - conversation_opened: Triggers when a snoozed/resolved conversation is reopened
    - conversation_resolved: Triggers when a conversation is marked as resolved
    - message_created: Triggers when a new message is posted in a conversation
  DESC

  ATTRIBUTES_DESC = <<~DESC
    **Available Condition Attributes:**
    - content: Message content text
    - email: Contact email address
    - country_code: Country code of contact
    - status: Conversation status (open, resolved, pending)
    - message_type: Message type (0=incoming, 1=outgoing)
    - browser_language: Browser language
    - assignee_id: Assigned agent ID
    - team_id: Assigned team ID
    - referer: Referrer URL
    - city: Contact city
    - company: Contact company name
    - inbox_id: Inbox ID
    - mail_subject: Email subject
    - phone_number: Contact phone number
    - priority: Conversation priority (urgent, high, medium, low, none)
    - conversation_language: Conversation language
    - labels: Conversation labels
  DESC

  OPERATORS_DESC = <<~DESC
    **Filter Operators:**
    - equal_to: Exact match
    - not_equal_to: Not equal
    - contains: Contains text
    - does_not_contain: Does not contain text
    - is_present: Field has value
    - is_not_present: Field is empty
    - starts_with: Starts with text

    **Query Operators (for combining conditions):**
    - AND: All conditions must match
    - OR: Any condition can match
    - First condition doesn't need query_operator
  DESC

  ACTIONS_DESC = <<~DESC
    **Available Actions:**
    - send_message: Send public message. Params: ["message text"]
    - add_label: Add labels. Params: ["label1", "label2"]
    - remove_label: Remove labels. Params: ["label1", "label2"]
    - send_email_to_team: Email team members. Params: [team_id, "message"]
    - assign_team: Assign to team. Params: [team_id]
    - assign_agent: Assign to agent. Params: [agent_id]
    - send_webhook_event: Trigger webhook. Params: ["https://webhook.url"]
    - mute_conversation: Mute notifications. Params: []
    - send_attachment: Send file attachment. Params: [blob_id]
    - change_status: Change status. Params: ["open"|"resolved"|"pending"]
    - resolve_conversation: Mark resolved. Params: []
    - open_conversation: Reopen conversation. Params: []
    - snooze_conversation: Snooze conversation. Params: []
    - change_priority: Change priority. Params: ["urgent"|"high"|"medium"|"low"|"none"]
    - send_email_transcript: Send transcript via email. Params: ["email@example.com"]
    - add_private_note: Add private note. Params: ["note content"]
    - execute_macro: Execute an existing macro. Params: [macro_id]
  DESC

  USE_CASES_DESC = <<~DESC
    **Common Use Cases:**
    1. Auto-label support requests: event="message_created", condition="content contains 'help'", action="add_label support"
    2. Assign VIP customers: event="conversation_created", condition="email contains '@vip.com'", action="assign_team [vip_team_id]"
    3. Auto-respond to keywords: event="message_created", condition="content contains 'refund'", action="send_message 'We process refunds...'"
    4. Escalate urgent: event="message_created", condition="content contains 'urgent' AND priority equals 'none'", action="change_priority high"
    5. Execute macro workflow: event="conversation_created", condition="status equals 'open'", action="execute_macro [macro_id]"

    Rules execute when the event occurs AND all conditions match. Actions run sequentially.
    For more details: https://www.chatwoot.com/hc/user-guide/articles/1677689800-how-to-use-automation
  DESC

  CONDITIONS_PARAM_DESC = <<~DESC
    JSON string containing an array of condition objects. Each condition must have:
    - attribute_key: One of the available attributes (content, email, status, etc.)
    - filter_operator: One of the filter operators (equal_to, contains, is_present, etc.)
    - values: Array of values to match (can be empty for is_present/is_not_present)
    - query_operator: "AND" or "OR" (only needed for conditions after the first one)
  DESC

  ACTIONS_PARAM_DESC = <<~DESC
    JSON string containing an array of action objects. Each action must have:
    - action_name: One of the available action types listed in the tool description
    - action_params: Array of parameters for that action (can be empty array)
    Actions execute in the order provided.
  DESC

  TOOL_DESCRIPTION = <<~DESC.freeze
    Create a new automation rule (workflow) that triggers actions based on events and conditions.

    **When to use:** Use this tool to create automated workflows that respond to events. For example: auto-labeling messages containing keywords, assigning conversations based on content, or sending automatic responses.

    #{EVENTS_DESC}
    #{ATTRIBUTES_DESC}
    #{OPERATORS_DESC}
    #{ACTIONS_DESC}
    #{USE_CASES_DESC}
  DESC
end
