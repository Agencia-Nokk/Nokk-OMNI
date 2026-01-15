require 'net/http'
require 'json'
require 'uri'
require 'openssl'

# rubocop:disable Metrics/ClassLength
class Uazapi::SseDaemon
  attr_reader :connections

  def initialize
    @connections = {}
    @running = false
    @mutex = Mutex.new
  end

  def start
    @running = true
    Rails.logger.info '[UAZAPI SSE] Starting SSE Daemon...'
    log 'Daemon starting...'

    ensure_dispatcher_initialized
    setup_signal_handlers
    run_loop
  end

  def ensure_dispatcher_initialized
    unless Rails.configuration.dispatcher
      log 'Initializing dispatcher...'
      Rails.configuration.dispatcher = Dispatcher.instance
      Rails.configuration.dispatcher.load_listeners
    end
    log "Dispatcher ready: #{Rails.configuration.dispatcher.class}"
  end

  def stop
    @running = false
    Rails.logger.info '[UAZAPI SSE] Stopping SSE Daemon...'
    log 'Daemon stopping...'
    close_all_connections
  end

  private

  def setup_signal_handlers
    %w[INT TERM].each do |signal|
      Signal.trap(signal) { stop }
    end
  end

  def run_loop
    while @running
      sync_channels
      sleep 30
    end
  end

  def sync_channels
    active_channel_ids = Channel::Uazapi.pluck(:id)
    current_channel_ids = @mutex.synchronize { @connections.keys.dup }

    current_channel_ids.each do |channel_id|
      close_connection(channel_id) unless active_channel_ids.include?(channel_id)
    end

    active_channel_ids.each do |channel_id|
      already_connected = @mutex.synchronize { @connections.key?(channel_id) }
      start_connection(channel_id) unless already_connected
    end
  end

  def start_connection(channel_id)
    channel = Channel::Uazapi.find_by(id: channel_id)
    return unless channel&.inbox

    log "Starting connection for channel #{channel_id}"

    thread = Thread.new { connect_with_retry(channel) }
    @mutex.synchronize { @connections[channel_id] = { thread: thread, channel: channel } }
  end

  def connect_with_retry(channel)
    retry_count = 0

    while @running
      begin
        connect_sse(channel)
        retry_count = 0
      rescue StandardError => e
        retry_count += 1
        delay = [5 * (2**retry_count), 300].min
        log "Connection error for channel #{channel.id}: #{e.message}. Retry #{retry_count}/10 in #{delay}s"
        break if retry_count >= 10

        sleep delay
      end
    end
  end

  def connect_sse(channel)
    uri = build_sse_uri(channel)
    http = build_http_client(uri)

    log "Connecting to SSE: #{channel.api_url} for channel #{channel.id}"

    http.start do
      http.request(build_sse_request(uri)) do |response|
        handle_sse_stream(response, channel)
      end
    end
  end

  def build_sse_uri(channel)
    uri = URI("#{channel.api_url}/sse")
    uri.query = URI.encode_www_form(token: channel.api_token, events: 'messages,messages_update,presence,groups,contacts,connection')
    uri
  end

  def build_http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.read_timeout = 300
    http
  end

  def build_sse_request(uri)
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'text/event-stream'
    request['Cache-Control'] = 'no-cache'
    request
  end

  def handle_sse_stream(response, channel)
    raise "SSE connection failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    log "Connected to channel #{channel.id}"
    buffer = ''

    response.read_body do |chunk|
      break unless @running

      buffer += chunk
      process_buffer(buffer, channel)
      buffer = extract_remaining(buffer)
    end
  end

  def process_buffer(buffer, channel)
    buffer.scan(/data:\s*(.+?)\n\n/m).each do |match|
      data = match[0].strip
      next if data.empty? || data == ':keepalive'

      process_event(data, channel)
    end
  end

  def extract_remaining(buffer)
    last_event = buffer.rindex("\n\n")
    return buffer unless last_event

    buffer[(last_event + 2)..]
  end

  def process_event(data, channel)
    params = JSON.parse(data)
    event_type = params['EventType'] || params['event'] || params['type']
    dispatch_event(event_type, channel, params)
  rescue JSON::ParserError => e
    log "JSON parse error: #{e.message}"
    log "Raw data: #{data[0..500]}"
  rescue StandardError => e
    log "Event processing error: #{e.message}"
    log e.backtrace&.first(5)&.join("\n")
  end

  def dispatch_event(event_type, channel, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    log "[#{event_type}] Channel #{channel.id}"
    log "Params: #{params.to_json[0..500]}"

    case event_type
    when 'messages'
      log 'Processing messages event...'
      Uazapi::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
      log 'Messages event processed!'
    when 'messages_update'
      log 'Processing messages_update event...'
      Uazapi::MessageStatusService.new(inbox: channel.inbox, params: params).perform
      log 'Messages_update event processed!'
    when 'presence'
      log 'Processing presence event...'
      Uazapi::PresenceService.new(inbox: channel.inbox, params: params).perform
      log 'Presence event processed!'
    when 'groups'
      log 'Processing groups event...'
      Uazapi::GroupUpdateService.new(inbox: channel.inbox, params: params).perform
      log 'Groups event processed!'
    when 'contacts', 'connection'
      log "Event #{event_type} received (handler not implemented yet)"
    else
      log "Unknown event type: #{event_type}"
    end
  rescue StandardError => e
    log "ERROR in #{event_type}: #{e.class} - #{e.message}"
    log "Backtrace: #{e.backtrace&.first(10)&.join("\n")}"
  end

  def close_connection(channel_id)
    @mutex.synchronize do
      conn = @connections.delete(channel_id)
      conn[:thread]&.kill if conn
    end
    log "Closed connection for channel #{channel_id}"
  end

  def close_all_connections
    channel_ids = @mutex.synchronize { @connections.keys.dup }
    channel_ids.each { |id| close_connection(id) }
  end

  def log(message)
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    File.open(Rails.root.join('log/uazapi_sse.log'), 'a') do |f|
      f.puts "[#{timestamp}] #{message}"
    end
  end
end
# rubocop:enable Metrics/ClassLength
