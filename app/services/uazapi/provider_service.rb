# rubocop:disable Metrics/ClassLength
class Uazapi::ProviderService
  def initialize(channel:)
    @channel = channel
  end

  def send_message(phone_number, message)
    is_group = phone_number&.include?('@g.us')
    log "[SEND] Message ID: #{message.id}, To: #{phone_number}, Group: #{is_group}, Attachments: #{message.attachments.count}"

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_text_message(phone_number, message)
    log "[TEXT] Sending text to #{phone_number}: #{message.content}"

    body = {
      number: phone_number,
      text: message.content,
      delay: 1000,
      readchat: true,
      track_source: 'chatwoot',
      track_id: message.id.to_s
    }

    # Add reply ID for quoted reply context (UAZAPI uses 'replyid' field)
    reply_id = quoted_message_id(message)
    body[:replyid] = reply_id if reply_id.present?
    log "[TEXT] Reply ID: #{reply_id}" if reply_id.present?

    response = HTTParty.post(
      "#{api_url}/send/text",
      headers: api_headers,
      body: body.to_json
    )

    log "[TEXT] Response: #{response.code} - #{response.body}"

    process_response(response)
  end

  # Simple text sending (for cart messages, confirmations, etc.)
  def send_text(phone_number, text)
    log "[TEXT] Sending simple text to #{phone_number}: #{text.truncate(100)}"

    body = {
      number: phone_number,
      text: text,
      delay: 1000,
      readchat: true,
      track_source: 'chatwoot'
    }

    response = HTTParty.post(
      "#{api_url}/send/text",
      headers: api_headers,
      body: body.to_json
    )

    log "[TEXT] Response: #{response.code}"
    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = attachment_type(attachment.file_type)
    file_base64 = attachment_to_base64(attachment)

    return log_attachment_error unless file_base64

    body = build_attachment_body(phone_number, message, type, file_base64, attachment)
    response = HTTParty.post("#{api_url}/send/media", headers: api_headers, body: body.to_json)

    process_response(response)
  end

  def build_attachment_body(phone_number, message, type, file_base64, attachment)
    body = { number: phone_number, type: type, file: file_base64, text: message.content,
             delay: 1000, track_source: 'chatwoot', track_id: message.id.to_s }
    body.delete(:text) if %w[audio ptt myaudio].include?(type)
    body[:docName] = attachment.file.filename.to_s if type == 'document'

    # Add reply ID for quoted reply context (UAZAPI uses 'replyid' field)
    reply_id = quoted_message_id(message)
    body[:replyid] = reply_id if reply_id.present?
    log "[MEDIA] Reply ID: #{reply_id}" if reply_id.present?

    body
  end

  def quoted_message_id(message)
    # Get the external ID of the message being replied to
    # content_attributes can have string or symbol keys
    attrs = message.content_attributes || {}
    external_id = attrs['in_reply_to_external_id'] || attrs[:in_reply_to_external_id]
    log "[REPLY] Looking for in_reply_to_external_id in: #{attrs.inspect}" if attrs.present? && attrs.keys.any? { |k| k.to_s.include?('reply') }
    external_id
  end

  def log_attachment_error
    log '[MEDIA] ERROR: Failed to convert attachment to base64'
    nil
  end

  def attachment_to_base64(attachment)
    content_type = attachment.file.content_type || 'application/octet-stream'
    file_data = read_attachment_data(attachment)
    "data:#{content_type};base64,#{Base64.strict_encode64(file_data)}"
  rescue StandardError => e
    log "[MEDIA] Error converting to base64: #{e.message}"
    nil
  end

  def read_attachment_data(attachment)
    attachment.file.blob.open(&:read)
  end

  def build_public_attachment_url(attachment)
    # Get the original download URL
    original_url = attachment.download_url

    # Replace localhost with FRONTEND_URL for external access
    frontend_url = ENV.fetch('FRONTEND_URL', nil)

    log "[URL DEBUG] Original URL: #{original_url}"
    log "[URL DEBUG] FRONTEND_URL env: #{frontend_url.inspect}"

    return original_url if frontend_url.blank?

    # Replace http://localhost:3000 or similar with the public URL
    public_url = original_url.sub(%r{https?://[^/]+}, frontend_url)

    log "[URL DEBUG] Public URL: #{public_url}"

    public_url
  end

  def delete_message(message)
    return if message.source_id.blank?

    response = HTTParty.post(
      "#{api_url}/message/delete",
      headers: api_headers,
      body: { id: message.source_id }.to_json
    )

    response.success?
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error deleting message: #{e.message}"
    false
  end

  def edit_message(message, new_content)
    return false if message.source_id.blank? || new_content.blank?

    response = HTTParty.post(
      "#{api_url}/message/edit",
      headers: api_headers,
      body: { id: message.source_id, text: new_content }.to_json
    )

    response.success?
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error editing message: #{e.message}"
    false
  end

  def send_presence(phone_number, presence_type = 'composing', delay_ms = 25_000)
    # presence_type: 'composing', 'recording', 'paused'
    response = HTTParty.post(
      "#{api_url}/message/presence",
      headers: api_headers,
      body: {
        number: phone_number,
        presence: presence_type,
        delay: delay_ms
      }.to_json
    )

    response.success?
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error sending presence: #{e.message}"
    false
  end

  def send_carousel(phone_number, text:, cards:, track_id: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    log "[CAROUSEL] Sending carousel to #{phone_number} with #{cards.length} cards"

    body = {
      number: phone_number,
      text: text,
      carousel: cards.map do |card|
        {
          text: card[:text],
          image: card[:image],
          buttons: card[:buttons]
        }
      end,
      delay: 300,
      readchat: true,
      track_source: 'chatwoot',
      track_id: track_id&.to_s
    }.compact

    response = HTTParty.post(
      "#{api_url}/send/carousel",
      headers: api_headers,
      body: body.to_json
    )

    log "[CAROUSEL] Response: #{response.code} - #{response.body}"

    if response.success?
      result = JSON.parse(response.body)
      { success: true, message_id: result['id'] || result['messageid'] }
    else
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error sending carousel: #{e.message}"
    { success: false, error: e.message }
  end

  def send_buttons(phone_number, text:, buttons:, footer: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    log "[BUTTONS] Sending buttons to #{phone_number}"

    # Format buttons for UAZAPI: "texto|reply:id" or "texto|url"
    choices = buttons.map do |btn|
      if btn[:type].to_s.casecmp('url').zero?
        "#{btn[:text]}|#{btn[:id]}"
      else
        "#{btn[:text]}|reply:#{btn[:id]}"
      end
    end

    body = {
      number: phone_number,
      type: 'button',
      text: text,
      choices: choices,
      footerText: footer,
      delay: 300,
      readchat: true
    }.compact

    response = HTTParty.post(
      "#{api_url}/send/menu",
      headers: api_headers,
      body: body.to_json
    )

    log "[BUTTONS] Response: #{response.code} - #{response.body}"

    if response.success?
      result = JSON.parse(response.body)
      { success: true, message_id: result['id'] || result['messageid'] }
    else
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error sending buttons: #{e.message}"
    { success: false, error: e.message }
  end

  def api_headers
    {
      'Content-Type' => 'application/json',
      'token' => @channel.api_token
    }
  end

  def api_url
    @channel.api_url
  end

  # Fetch all chats from UAZAPI
  def fetch_chats(limit: 2000, offset: 0)
    response = HTTParty.post(
      "#{api_url}/chat/find",
      headers: api_headers,
      body: {
        sort: '-wa_lastMsgTimestamp',
        limit: limit,
        offset: offset
      }.to_json
    )

    return { chats: [], pagination: {} } unless response.success?

    body = JSON.parse(response.body)
    {
      chats: body['chats'] || [],
      pagination: body['pagination'] || {}
    }
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error fetching chats: #{e.message}"
    { chats: [], pagination: {} }
  end

  # Fetch messages for a specific chat
  def fetch_messages(chat_id, limit: 20)
    response = HTTParty.post(
      "#{api_url}/message/find",
      headers: api_headers,
      body: {
        chatid: chat_id,
        limit: limit
      }.to_json
    )

    return [] unless response.success?

    body = JSON.parse(response.body)
    body['messages'] || []
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error fetching messages for #{chat_id}: #{e.message}"
    []
  end

  # Fetch contact details
  def fetch_contact_details(phone_number)
    response = HTTParty.post(
      "#{api_url}/chat/details",
      headers: api_headers,
      body: { number: phone_number, preview: false }.to_json
    )

    return nil unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error fetching contact details: #{e.message}"
    nil
  end

  private

  def log(message)
    File.open(Rails.root.join('log/uazapi_debug.log'), 'a') do |f|
      f.puts "[#{Time.current}] #{message}"
    end
  end

  def attachment_type(file_type)
    case file_type
    when 'image' then 'image'
    when 'audio' then 'ptt'
    when 'video' then 'video'
    else 'document'
    end
  end

  def process_response(response)
    return nil unless response.success?

    body = JSON.parse(response.body)
    body['id'] || body['messageid']
  rescue StandardError => e
    Rails.logger.error "[UAZAPI] Error processing response: #{e.message}"
    nil
  end
end
# rubocop:enable Metrics/ClassLength
