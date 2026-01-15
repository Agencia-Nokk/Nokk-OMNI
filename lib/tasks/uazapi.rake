namespace :uazapi do
  desc 'Start SSE daemon to receive events from all UAZAPI channels'
  task sse_daemon: :environment do
    require_relative '../uazapi/sse_daemon'

    puts 'Starting UAZAPI SSE Daemon...'
    puts 'Logs: log/uazapi_sse.log'
    puts 'Press Ctrl+C to stop'

    daemon = Uazapi::SseDaemon.new
    daemon.start
  end

  desc 'Check UAZAPI channel connections status'
  task status: :environment do
    channels = Channel::Uazapi.includes(:inbox).all
    puts "UAZAPI Channels Status (#{channels.count} total):"
    puts '-' * 60

    channels.find_each do |channel|
      inbox_name = channel.inbox&.name || 'No inbox'
      puts "Channel #{channel.id}:"
      puts "  Phone: #{channel.phone_number}"
      puts "  Inbox: #{inbox_name}"
      puts "  API URL: #{channel.api_url}"
      puts ''
    end
  end
end
