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
  validate :validate_provider_config

  # SSE connections are managed by the uazapi_sse daemon process
  # New channels are detected automatically every 30 seconds

  def name
    'UAZAPI'
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
    provider_config['api_url']
  end

  def api_token
    provider_config['api_token']
  end

  private

  def validate_provider_config
    return if provider_config.blank?

    errors.add(:provider_config, 'api_url is required') if provider_config['api_url'].blank?
    errors.add(:provider_config, 'api_token is required') if provider_config['api_token'].blank?
  end
end
