# rubocop:disable Metrics/ClassLength
class Uazapi::InitialSyncJob < ApplicationJob
  queue_as :low

  # UAZAPI color index (0-19) to hex color mapping
  UAZAPI_COLOR_MAP = {
    0 => '#64748b',  # Cinza
    1 => '#ec4899',  # Rosa
    2 => '#f97316',  # Laranja
    3 => '#eab308',  # Amarelo
    4 => '#22c55e',  # Verde
    5 => '#14b8a6',  # Teal
    6 => '#06b6d4',  # Ciano
    7 => '#3b82f6',  # Azul
    8 => '#6366f1',  # Indigo
    9 => '#8b5cf6',  # Violeta
    10 => '#a855f7', # Roxo
    11 => '#d946ef', # Fúcsia
    12 => '#ef4444', # Vermelho
    13 => '#78716c', # Stone
    14 => '#84cc16', # Lime
    15 => '#10b981', # Emerald
    16 => '#0ea5e9', # Sky
    17 => '#6d28d9', # Violet Dark
    18 => '#be185d', # Pink Dark
    19 => '#b91c1c'  # Red Dark
  }.freeze

  # WhatsApp system labels to skip
  SYSTEM_LABELS = %w[grupos não-lidas favoritos nao-lidas].freeze

  # Batch size for scheduling child jobs
  BATCH_SIZE = 50

  def perform(channel_id, options = {})
    @channel = Channel::Uazapi.find_by(id: channel_id)
    return unless @channel&.inbox

    @options = options.with_indifferent_access
    @label_map = {}

    if @options[:batch_mode]
      # Processing a specific batch of chats
      process_batch
    else
      # Orchestrator mode: sync labels and schedule batches
      orchestrate_sync
    end
  rescue StandardError => e
    log "ERROR: #{e.class} - #{e.message}"
    update_sync_status('failed', current_progress[:synced], current_progress[:total], e.message)
    raise
  end

  private

  # ============ ORCHESTRATOR MODE ============

  def orchestrate_sync
    log 'Starting initial sync (orchestrator)...'
    update_sync_status('syncing', 0, 0)

    # Step 1: Sync labels first (fast, do it here)
    sync_labels
    store_label_map

    # Step 2: Fetch total chat count and schedule batches
    schedule_batches
  end

  def sync_labels
    errors_count = 0
    uazapi_labels = provider_service.fetch_labels

    uazapi_labels.each do |uazapi_label|
      label_id = uazapi_label['id'] || uazapi_label['labelid']
      label_name = uazapi_label['name']
      label_color = uazapi_label['color']

      next if label_id.blank? || label_name.blank?

      sanitized_title = sanitize_label_title(label_name)
      next if sanitized_title.blank?
      next if SYSTEM_LABELS.include?(sanitized_title)

      chatwoot_label = account.labels.find_or_create_by!(title: sanitized_title) do |label|
        label.color = UAZAPI_COLOR_MAP[label_color.to_i] || '#7a4aff'
        label.description = "Importado da UAZAPI: #{label_name}"
        label.show_on_sidebar = true
      end

      @label_map[label_id.to_s] = chatwoot_label.title
    rescue ActiveRecord::RecordInvalid
      errors_count += 1
    end

    log "Labels: #{@label_map.keys.length} synced, #{errors_count} errors"
  end

  def store_label_map
    # Store label map in provider_config for batch jobs to use
    config = @channel.provider_config || {}
    config['label_map'] = @label_map
    @channel.update_column(:provider_config, config)
  end

  def schedule_batches
    # Fetch all chats in one request to get the list
    result = provider_service.fetch_chats(limit: 5000, offset: 0)
    all_chats = result[:chats]
    total = all_chats.length

    if all_chats.empty?
      update_sync_status('completed', 0, 0)
      log 'No chats to sync'
      return
    end

    # Initialize progress tracking
    update_sync_status('syncing', 0, total)
    init_batch_tracking(total)

    # Schedule batch jobs
    all_chats.each_slice(BATCH_SIZE).with_index do |batch_chats, batch_index|
      # Extract minimal data needed for batch processing
      chat_ids = batch_chats.map { |c| { id: c['wa_chatid'] || c['id'], data: c } }

      Uazapi::InitialSyncJob.perform_later(
        @channel.id,
        {
          batch_mode: true,
          batch_index: batch_index,
          chats: chat_ids,
          total: total
        }
      )

      log "Scheduled batch #{batch_index + 1} with #{batch_chats.length} chats"
    end

    log "Orchestrator done: scheduled #{(total.to_f / BATCH_SIZE).ceil} batches for #{total} chats"
  end

  def init_batch_tracking(total)
    config = @channel.provider_config || {}
    config['sync_batches'] = {
      'total_chats' => total,
      'total_batches' => (total.to_f / BATCH_SIZE).ceil,
      'completed_batches' => 0,
      'synced_contacts' => 0,
      'started_at' => Time.current.iso8601
    }
    @channel.update_column(:provider_config, config)
  end

  # ============ BATCH MODE ============

  def process_batch
    batch_index = @options[:batch_index]
    chats = @options[:chats]
    total = @options[:total]

    log "Processing batch #{batch_index + 1} with #{chats.length} chats..."

    # Load label map from provider_config
    @label_map = @channel.provider_config&.dig('label_map') || {}

    synced = 0
    chats.each do |chat_info|
      chat_id = chat_info['id'] || chat_info[:id]
      chat_data = chat_info['data'] || chat_info[:data]

      sync_chat(chat_data, chat_id)
      synced += 1

      # Small delay between contacts to avoid overwhelming
      sleep 0.1
    end

    # Update batch completion
    update_batch_progress(batch_index, synced, total)
  end

  def update_batch_progress(batch_index, synced_in_batch, total)
    config = @channel.reload.provider_config || {}
    batches = config['sync_batches'] || {}

    batches['completed_batches'] = (batches['completed_batches'] || 0) + 1
    batches['synced_contacts'] = (batches['synced_contacts'] || 0) + synced_in_batch

    total_synced = batches['synced_contacts']
    total_batches = batches['total_batches']
    completed_batches = batches['completed_batches']

    config['sync_batches'] = batches
    @channel.update_column(:provider_config, config)

    # Broadcast progress
    broadcast_sync_status('syncing', total_synced, total, nil)

    # Check if all batches completed
    finalize_sync(total_synced, total) if completed_batches >= total_batches

    log "Batch #{batch_index + 1} done: #{synced_in_batch} contacts (#{total_synced}/#{total} total)"
  end

  def finalize_sync(total_synced, total)
    update_sync_status('completed', total_synced, total)
    log "Sync completed: #{total_synced}/#{total} contacts"
  end

  # ============ CHAT SYNC LOGIC ============

  def sync_chat(chat_data, chat_id)
    return if chat_id.blank?

    is_group = chat_id.include?('@g.us')
    source_id = is_group ? chat_id : chat_id.gsub(/@.*/, '')

    @current_chat_timestamp = extract_chat_timestamp(chat_data)
    @current_chat_data = chat_data

    contact_inbox = @channel.inbox.contact_inboxes.find_by(source_id: source_id)
    if contact_inbox
      sync_conversation_for_contact(contact_inbox, chat_id)
      return
    end

    contact = find_or_create_contact(chat_data, source_id, is_group)
    return unless contact

    contact_inbox = ContactInbox.create!(
      contact: contact,
      inbox: @channel.inbox,
      source_id: source_id
    )

    sync_conversation_for_contact(contact_inbox, chat_id)
  rescue ActiveRecord::RecordNotUnique
    # Already exists
  rescue StandardError => e
    log "Error syncing chat #{chat_id}: #{e.message}"
  end

  def sync_conversation_for_contact(contact_inbox, chat_id)
    conversation = contact_inbox.conversations.first
    conversation ||= create_conversation(contact_inbox)
    return unless conversation

    apply_labels_to_conversation(conversation)

    # Fetch limited messages (reduce load)
    messages = provider_service.fetch_messages(chat_id, limit: 20)

    if messages.empty?
      conversation.update!(
        additional_attributes: (conversation.additional_attributes || {}).merge('uazapi_no_history' => true)
      )
      return
    end

    import_messages(conversation, messages)

    last_message = conversation.messages.order(created_at: :desc).first
    conversation.update!(last_activity_at: last_message.created_at) if last_message
  rescue StandardError => e
    log "Error syncing messages for #{chat_id}: #{e.message}"
  end

  def apply_labels_to_conversation(conversation)
    return if @label_map.blank? || @current_chat_data.blank?

    wa_label_raw = @current_chat_data['wa_label']
    return if wa_label_raw.blank?

    label_ids = wa_label_raw.is_a?(String) ? JSON.parse(wa_label_raw) : wa_label_raw
    return if label_ids.blank? || !label_ids.is_a?(Array)

    chatwoot_labels = label_ids.filter_map { |id| @label_map[id.to_s] }.uniq
    return if chatwoot_labels.blank?

    conversation.update_labels(chatwoot_labels)
    conversation.contact&.update_labels(chatwoot_labels)
  rescue JSON::ParserError, StandardError
    # Skip label errors silently
  end

  def create_conversation(contact_inbox)
    Conversation.create!(
      account: @channel.inbox.account,
      inbox: @channel.inbox,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox,
      status: :open,
      last_activity_at: @current_chat_timestamp || Time.current
    )
  end

  def import_messages(conversation, messages)
    sorted_messages = messages.sort_by { |m| m['timestamp'] || 0 }
    sorted_messages.each { |msg| import_message(conversation, msg) }
  end

  def import_message(conversation, msg_data)
    message_id = extract_message_id(msg_data)
    return if message_id.blank?
    return if conversation.messages.exists?(source_id: message_id)

    content = msg_data['text'] || msg_data['caption'] || ''
    from_me = msg_data['fromMe'] == true
    timestamp = msg_data['timestamp']

    conversation.messages.create!(
      account: @channel.inbox.account,
      inbox: @channel.inbox,
      content: content,
      message_type: from_me ? :outgoing : :incoming,
      source_id: message_id,
      sender: from_me ? nil : conversation.contact,
      created_at: timestamp ? Time.zone.at(timestamp) : Time.current
    )

    # Skip media on initial sync to speed up (can be fetched on-demand)
    # import_media(message, msg_data) if has_media?(msg_data)
  rescue ActiveRecord::RecordNotUnique, StandardError
    # Skip silently
  end

  # ============ HELPERS ============

  def extract_message_id(msg_data)
    raw_id = msg_data['messageid'] || msg_data['id']
    return nil if raw_id.blank?

    raw_id.include?(':') ? raw_id.split(':').last : raw_id
  end

  def extract_chat_timestamp(chat_data)
    timestamp = chat_data['lastMessageTime'] || chat_data['last_message_time'] ||
                chat_data['timestamp'] || chat_data['t']
    return Time.zone.at(timestamp) if timestamp.is_a?(Integer) && timestamp.positive?

    1.year.ago
  end

  def sanitize_label_title(name)
    name.to_s
        .downcase
        .gsub(/\s+/, '-')
        .gsub(/[^a-z0-9\-_\u00C0-\u024F]/, '').squeeze('-')
        .gsub(/^-|-$/, '')
        .truncate(50, omission: '')
  end

  def find_or_create_contact(chat_data, source_id, is_group)
    if is_group
      create_group_contact(chat_data, source_id)
    else
      create_individual_contact(chat_data, source_id)
    end
  end

  def create_group_contact(chat_data, source_id)
    name = chat_data['wa_name'] || chat_data['name'] || "Grupo #{source_id.split('@').first[-6..]}"

    Contact.find_or_create_by!(
      account: @channel.inbox.account,
      identifier: source_id
    ) do |c|
      c.name = name
      c.additional_attributes = { is_group: true, group_id: source_id }
    end
  end

  def create_individual_contact(chat_data, source_id)
    phone = "+#{source_id.delete('+')}"
    name = chat_data['wa_name'] || chat_data['wa_contactName'] || chat_data['name'] || phone

    Contact.find_or_create_by!(
      account: @channel.inbox.account,
      phone_number: phone
    ) do |c|
      c.name = name
    end
  end

  def current_progress
    batches = @channel.reload.provider_config&.dig('sync_batches') || {}
    { synced: batches['synced_contacts'] || 0, total: batches['total_chats'] || 0 }
  end

  def update_sync_status(status, synced, total, error = nil)
    config = @channel.provider_config || {}
    config['sync_status'] = status
    config['sync_progress'] = { synced: synced, total: total }
    config['sync_error'] = error
    config['sync_updated_at'] = Time.current.iso8601
    @channel.update_column(:provider_config, config)

    broadcast_sync_status(status, synced, total, error)
  end

  def broadcast_sync_status(status, synced, total, error)
    ActionCable.server.broadcast(
      "account_#{@channel.inbox.account_id}",
      {
        event: 'uazapi.sync_status',
        data: {
          account_id: @channel.inbox.account_id,
          inbox_id: @channel.inbox.id,
          status: status,
          synced: synced,
          total: total,
          error: error,
          percentage: total.positive? ? ((synced.to_f / total) * 100).round : 0
        }
      }
    )
  rescue StandardError
    # Silent
  end

  def provider_service
    @provider_service ||= Uazapi::ProviderService.new(channel: @channel)
  end

  def account
    @channel.inbox.account
  end

  def log(message)
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    File.open(Rails.root.join('log/uazapi_sync.log'), 'a') do |f|
      f.puts "[#{timestamp}] [InitialSync] #{message}"
    end
  end
end
# rubocop:enable Metrics/ClassLength
