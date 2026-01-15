class Uazapi::GroupUpdateService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if group_id.blank?

    find_contact
    return if @contact.blank?

    update_group_info
  end

  private

  def event_data
    @event_data ||= @params['event'] || @params['data'] || @params
  end

  def group_id
    event_data['chatid'] || event_data['id'] || event_data['groupId']
  end

  def group_name
    event_data['name'] || event_data['subject'] || event_data['wa_name']
  end

  def group_image_url
    event_data['image'] || event_data['imagePreview'] || event_data['profilePicUrl']
  end

  def find_contact
    # Groups are stored as contacts with identifier = group_id
    @contact = inbox.contacts.find_by(identifier: group_id)

    # Fallback: try to find by source_id in contact_inbox
    return if @contact.present?

    contact_inbox = inbox.contact_inboxes.find_by(source_id: group_id)
    @contact = contact_inbox&.contact
  end

  def update_group_info
    update_group_name if group_name.present?
    update_group_avatar if group_image_url.present?
  end

  def update_group_name
    return if @contact.name == group_name

    @contact.update!(name: group_name)
    Rails.logger.info "[UAZAPI Groups] Updated group name: #{group_name}"
  end

  def update_group_avatar
    # Always update avatar (remove old one first if exists)
    @contact.avatar.purge if @contact.avatar.attached?

    file = Down.download(group_image_url)
    @contact.avatar.attach(
      io: file,
      filename: "group_#{group_id.split('@').first}.jpg",
      content_type: 'image/jpeg'
    )
    Rails.logger.info "[UAZAPI Groups] Updated group avatar for: #{group_id}"
  rescue Down::Error => e
    Rails.logger.error "[UAZAPI Groups] Failed to download group avatar: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[UAZAPI Groups] Error updating group avatar: #{e.message}"
  end
end
