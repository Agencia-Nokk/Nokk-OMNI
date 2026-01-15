class Uazapi::FetchHistoryJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    Uazapi::FetchHistoryService.new(conversation: conversation).perform
  end
end
