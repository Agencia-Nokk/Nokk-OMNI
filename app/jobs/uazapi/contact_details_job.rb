class Uazapi::ContactDetailsJob < ApplicationJob
  queue_as :low

  def perform(contact_id, channel_id, phone_number)
    @contact = Contact.find_by(id: contact_id)
    @channel = Channel::Uazapi.find_by(id: channel_id)
    return unless @contact && @channel

    fetch_and_update_contact_details(phone_number)
  end

  private

  def fetch_and_update_contact_details(phone_number)
    response = HTTParty.post(
      "#{@channel.api_url}/chat/details",
      headers: @channel.api_headers,
      body: { number: phone_number, preview: false }.to_json
    )

    return unless response.success?

    data = JSON.parse(response.body)
    update_contact_with_details(data)
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] ContactDetailsJob error: #{e.message}"
  end

  def update_contact_with_details(data)
    # Atualizar nome se disponível e contato ainda não tem nome
    name = data['wa_name'] || data['wa_contactName'] || data['name']
    @contact.update!(name: name) if name.present? && @contact.name == @contact.phone_number

    # Atualizar avatar (foto de perfil)
    update_contact_avatar(data['image']) if data['image'].present?
  end

  def update_contact_avatar(image_url)
    return if image_url.blank?
    return if @contact.avatar.attached?

    avatar_file = Down.download(image_url)
    @contact.avatar.attach(
      io: avatar_file,
      filename: "avatar_#{@contact.id}.jpg",
      content_type: 'image/jpeg'
    )
  rescue Down::Error => e
    Rails.logger.error "[UAZAPI] Failed to download avatar: #{e.message}"
  end
end
