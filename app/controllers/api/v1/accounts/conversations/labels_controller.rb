class Api::V1::Accounts::Conversations::LabelsController < Api::V1::Accounts::Conversations::BaseController
  include LabelConcern

  def create
    super
    sync_labels_to_contact
  end

  private

  def model
    @model ||= @conversation
  end

  def permitted_params
    params.permit(:conversation_id, labels: [])
  end

  def sync_labels_to_contact
    return if @labels.blank? || @conversation.contact.blank?

    @conversation.contact.add_labels(@labels)
  end
end
