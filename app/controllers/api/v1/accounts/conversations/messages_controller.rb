class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update
  after_action :trigger_uazapi_history_fetch, only: :index

  def index
    @messages = message_finder.perform
  end

  def edit
    new_content = params[:content]
    return render json: { error: 'Content is required' }, status: :unprocessable_content if new_content.blank?

    ActiveRecord::Base.transaction do
      edit_message_in_channel(new_content)
      message.update!(content: new_content)
    end

    @message = message
  end

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
    @message = message
  end

  def destroy
    ActiveRecord::Base.transaction do
      delete_message_from_channel
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  end

  def retry
    return if message.blank?

    service = Messages::StatusUpdateService.new(message, 'sent')
    service.perform
    message.update!(content_attributes: {})
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: permitted_params[:target_language]
    ).perform

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations)
    end

    render json: { content: translated_content }
  end

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  def delete_message_from_channel
    channel = @conversation.inbox.channel
    return unless channel.is_a?(Channel::Uazapi)

    Uazapi::ProviderService.new(channel: channel).delete_message(message)
  end

  def edit_message_in_channel(new_content)
    channel = @conversation.inbox.channel
    return unless channel.is_a?(Channel::Uazapi)

    Uazapi::ProviderService.new(channel: channel).edit_message(message, new_content)
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end

  # Trigger history fetch for UAZAPI channels when conversation is opened
  def trigger_uazapi_history_fetch
    return unless @conversation.inbox.uazapi?
    return if @conversation.messages.where.not(message_type: :activity).exists?

    Uazapi::FetchHistoryJob.perform_later(@conversation.id)
  end
end
