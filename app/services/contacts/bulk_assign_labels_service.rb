class Contacts::BulkAssignLabelsService
  def initialize(account:, contact_ids:, labels:)
    @account = account
    @contact_ids = Array(contact_ids)
    @labels = Array(labels).compact_blank
  end

  def perform
    return { success: true, updated_contact_ids: [] } if @contact_ids.blank? || @labels.blank?

    contacts = @account.contacts.where(id: @contact_ids)

    contacts.find_each do |contact|
      contact.add_labels(@labels)
      sync_labels_to_conversations(contact)
    end

    { success: true, updated_contact_ids: contacts.pluck(:id) }
  end

  private

  def sync_labels_to_conversations(contact)
    contact.conversations.find_each do |conversation|
      conversation.add_labels(@labels)
    end
  end
end
