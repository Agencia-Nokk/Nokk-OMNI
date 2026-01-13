class Webhooks::UazapiEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {}, phone_number = nil)
    @params = params
    @phone_number = phone_number || params['phone_number']

    log '========== WEBHOOK RECEIVED =========='
    log "Phone: #{@phone_number}"
    log "Params: #{params.to_json}"

    channel = find_channel
    unless channel&.inbox
      log "ERROR: Channel not found for phone #{@phone_number}"
      return
    end

    log "Channel found: #{channel.id}, Inbox: #{channel.inbox.name}"

    # UAZAPI uses 'EventType' instead of 'event'
    event = params['EventType'] || params['event']
    log "Event type: #{event}"

    case event
    when 'messages'
      log 'Processing incoming message...'
      process_message(channel)
      log 'Message processed!'
    when 'messages_update'
      log 'Processing status update...'
      process_status_update(channel)
    else
      log "Unknown event type: #{event}"
    end
  end

  private

  def log(message)
    File.open(Rails.root.join('log/uazapi_debug.log'), 'a') do |f|
      f.puts "[#{Time.current}] #{message}"
    end
  end

  def find_channel
    return unless @phone_number

    Channel::Uazapi.find_by(phone_number: @phone_number)
  end

  def process_message(channel)
    Uazapi::IncomingMessageService.new(
      inbox: channel.inbox,
      params: @params
    ).perform
  end

  def process_status_update(channel)
    Uazapi::MessageStatusService.new(
      inbox: channel.inbox,
      params: @params
    ).perform
  end
end
