class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation)
    super(conversation)
    @rule = rule
    @account = account
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @conversation.reload
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    return unless @rule.files.attached?

    blobs = ActiveStorage::Blob.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
    end
  end

  def execute_macro(macro_ids)
    return if macro_ids.blank?

    macro_id = macro_ids[0]
    macro = @account.macros.find_by(id: macro_id)
    return unless macro

    # Determine the user to use as 'self' for macro execution
    # Priority: 1) Current assignee, 2) Last agent who sent a message, 3) nil
    user = determine_macro_user

    # Execute macro using Macros::ExecutionService
    ::Macros::ExecutionService.new(macro, @conversation, user).perform
  end

  def determine_macro_user
    # First, try to use the current assignee (if belongs to the account)
    if @conversation.assignee.present? && @conversation.assignee.account_users.exists?(account_id: @account.id)
      return @conversation.assignee
    end

    # If no assignee, try to find the last agent who sent a message in this conversation
    last_agent_message = @conversation.messages
                                      .where(sender_type: 'User')
                                      .where.not(sender_id: nil)
                                      .order(created_at: :desc)
                                      .first

    if last_agent_message&.sender.present?
      user = last_agent_message.sender
      # Ensure the user belongs to the account
      return user if user.account_users.exists?(account_id: @account.id)
    end

    # If no agent found, return nil (macro actions that depend on 'self' won't work)
    nil
  end
end
