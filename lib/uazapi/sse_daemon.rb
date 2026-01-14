require 'net/http'
require 'json'
require 'uri'
require 'openssl'

module Uazapi
  class SseDaemon
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

      # Ensure dispatcher is initialized for real-time events
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
        sleep 30 # Check for new channels every 30 seconds
      end
    end

    def sync_channels
      active_channel_ids = Channel::Uazapi.pluck(:id)

      # Get current connection IDs with mutex protection
      current_channel_ids = @mutex.synchronize { @connections.keys.dup }

      # Remove connections for deleted channels
      current_channel_ids.each do |channel_id|
        close_connection(channel_id) unless active_channel_ids.include?(channel_id)
      end

      # Start connections for new channels
      active_channel_ids.each do |channel_id|
        already_connected = @mutex.synchronize { @connections.key?(channel_id) }
        start_connection(channel_id) unless already_connected
      end
    end

    def start_connection(channel_id)
      channel = Channel::Uazapi.find_by(id: channel_id)
      return unless channel&.inbox

      log "Starting connection for channel #{channel_id}"

      thread = Thread.new do
        connect_with_retry(channel)
      end

      @mutex.synchronize do
        @connections[channel_id] = { thread: thread, channel: channel }
      end
    end

    def connect_with_retry(channel)
      retry_count = 0
      max_retries = 10
      base_delay = 5

      while @running
        begin
          connect_sse(channel)
          retry_count = 0 # Reset on successful connection
        rescue StandardError => e
          retry_count += 1
          delay = [base_delay * (2**retry_count), 300].min # Max 5 minutes

          log "Connection error for channel #{channel.id}: #{e.message}. Retry #{retry_count}/#{max_retries} in #{delay}s"

          break if retry_count >= max_retries

          sleep delay
        end
      end
    end

    def connect_sse(channel)
      uri = URI("#{channel.api_url}/sse")
      uri.query = URI.encode_www_form(
        token: channel.api_token,
        events: 'messages,messages_update,presence'
      )

      log "Connecting to SSE: #{channel.api_url} for channel #{channel.id}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification
      http.read_timeout = 300

      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'text/event-stream'
      request['Cache-Control'] = 'no-cache'

      http.start do
        http.request(request) do |response|
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

      log '========== SSE EVENT RECEIVED =========='
      log "Channel: #{channel.id} (#{channel.phone_number})"
      log "Event type: #{event_type}"
      log "Params: #{params.to_json}"

      case event_type
      when 'messages'
        log 'Processing incoming message...'
        service = Uazapi::IncomingMessageService.new(inbox: channel.inbox, params: params)
        log "Media type: #{params.dig('message', 'mediaType')}"
        log "Message type: #{params.dig('message', 'type')}"
        quoted_id = params.dig('message', 'quoted')
        log "Quoted message ID: #{quoted_id}" if quoted_id.present?
        content = params.dig('message', 'content')
        content_url = content.is_a?(Hash) ? content['URL']&.slice(0, 80) : nil
        log "Content URL: #{content_url}"
        service.perform
        log 'Message processed!'
      when 'messages_update'
        log 'Processing status update...'
        Uazapi::MessageStatusService.new(inbox: channel.inbox, params: params).perform
        log 'Status update processed!'
      when 'presence'
        log 'Processing presence update...'
        Uazapi::PresenceService.new(inbox: channel.inbox, params: params).perform
        log 'Presence update processed!'
      else
        log "Unknown event type: #{event_type}"
      end
    rescue JSON::ParserError => e
      log "JSON parse error: #{e.message}"
      log "Raw data: #{data[0..500]}"
    rescue StandardError => e
      log "Event processing error: #{e.message}"
      log e.backtrace&.first(5)&.join("\n")
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
end
