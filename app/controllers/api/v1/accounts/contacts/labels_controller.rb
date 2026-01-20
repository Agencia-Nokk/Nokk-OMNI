class Api::V1::Accounts::Contacts::LabelsController < Api::V1::Accounts::Contacts::BaseController
  include LabelConcern

  def create
    super
    sync_labels_to_conversations
  end

  private

  def model
    @model ||= @contact
  end

  def permitted_params
    params.permit(labels: [])
  end

  def sync_labels_to_conversations
    return if @labels.blank?

    @contact.conversations.find_each do |conversation|
      conversation.add_labels(@labels)
    end
  end
end
