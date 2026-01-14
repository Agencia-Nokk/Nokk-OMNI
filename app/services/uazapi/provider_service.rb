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

    response = HTTParty.post(
      "#{api_url}/send/text",
      headers: api_headers,
      body: {
        number: phone_number,
        text: message.content,
        delay: 1000,
        readchat: true,
        track_source: 'chatwoot',
        track_id: message.id.to_s
      }.to_json
    )

    log "[TEXT] Response: #{response.code} - #{response.body}"

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = attachment_type(attachment.file_type)

    log "[MEDIA] Sending #{type} to #{phone_number}"

    # Download file and convert to base64
    file_base64 = attachment_to_base64(attachment)

    unless file_base64
      log '[MEDIA] ERROR: Failed to convert attachment to base64'
      return nil
    end

    body = {
      number: phone_number,
      type: type,
      file: file_base64,
      text: message.content,
      delay: 1000,
      track_source: 'chatwoot',
      track_id: message.id.to_s
    }

    # Áudio/PTT não suporta caption
    body.delete(:text) if %w[audio ptt myaudio].include?(type)

    # Documento precisa do nome do arquivo
    body[:docName] = attachment.file.filename.to_s if type == 'document'

    log "[MEDIA] Sending base64 (#{file_base64.length} chars)"

    response = HTTParty.post(
      "#{api_url}/send/media",
      headers: api_headers,
      body: body.to_json
    )

    log "[MEDIA] Response: #{response.code} - #{response.body}"

    process_response(response)
  end

  def attachment_to_base64(attachment)
    # Read file directly from ActiveStorage
    file_data = attachment.file.download
    content_type = attachment.file.content_type || 'application/octet-stream'

    # Build data URI
    base64_data = Base64.strict_encode64(file_data)
    "data:#{content_type};base64,#{base64_data}"
  rescue StandardError => e
    log "[MEDIA] Error converting to base64: #{e.message}"
    nil
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

  def api_headers
    {
      'Content-Type' => 'application/json',
      'token' => @channel.api_token
    }
  end

  def api_url
    @channel.api_url
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
