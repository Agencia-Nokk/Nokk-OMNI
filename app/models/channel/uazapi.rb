# == Schema Information
#
# Table name: channel_uazapi
#
#  id              :bigint           not null, primary key
#  phone_number    :string           not null
#  provider_config :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#
# Indexes
#
#  index_channel_uazapi_on_phone_number  (phone_number) UNIQUE
#  index_channel_uazapi_on_account_id    (account_id)
#

class Channel::Uazapi < ApplicationRecord
  include Channelable

  self.table_name = 'channel_uazapi'

  EDITABLE_ATTRS = [:phone_number, { provider_config: {} }].freeze

  validates :phone_number, presence: true, uniqueness: true
  validates :provider_config, presence: true
  validate :validate_provider_config

  after_commit :verify_api_connection, on: :create
  after_commit :trigger_initial_sync, on: :create

  # SSE connections are managed by the uazapi_sse daemon process
  # New channels are detected automatically every 30 seconds

  def name
    'UAZAPI'
  end

  def provider
    'uazapi'
  end

  # Sync status methods
  def sync_status
    provider_config&.dig('sync_status') || 'pending'
  end

  def sync_progress
    provider_config&.dig('sync_progress') || { synced: 0, total: 0 }
  end

  def sync_in_progress?
    sync_status == 'syncing'
  end

  def sync_completed?
    sync_status == 'completed'
  end

  def start_sync!
    Uazapi::InitialSyncJob.perform_later(id)
  end

  def provider_service
    @provider_service ||= Uazapi::ProviderService.new(channel: self)
  end

  delegate :send_message, to: :provider_service
  delegate :api_headers, to: :provider_service

  # Configurações do provider_config:
  # - api_url: URL da instância UAZAPI (ex: https://seudominio.uazapi.com)
  # - api_token: Token da instância

  def api_url
    provider_config&.dig('api_url')
  end

  def api_token
    provider_config&.dig('api_token')
  end

  private

  def validate_provider_config
    return if provider_config.blank?

    errors.add(:provider_config, 'api_url is required') if provider_config['api_url'].blank?
    errors.add(:provider_config, 'api_token is required') if provider_config['api_token'].blank?
  end

  def verify_api_connection
    response = HTTParty.get(
      "#{api_url}/instance/status",
      headers: { 'token' => api_token }
    )
    Rails.logger.info "[UAZAPI] Channel #{id} created. API status: #{response.code}"
  rescue StandardError => e
    Rails.logger.warn "[UAZAPI] Channel #{id} created but API verification failed: #{e.message}"
  end

  def trigger_initial_sync
    # Wait a bit for inbox to be created, then start sync
    Uazapi::InitialSyncJob.set(wait: 5.seconds).perform_later(id)
    Rails.logger.info "[UAZAPI] Channel #{id} - Initial sync job scheduled"
  rescue StandardError => e
    Rails.logger.warn "[UAZAPI] Channel #{id} - Failed to schedule initial sync: #{e.message}"
  end
end
