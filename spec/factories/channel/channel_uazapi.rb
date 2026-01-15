# frozen_string_literal: true

FactoryBot.define do
  factory :channel_uazapi, class: 'Channel::Uazapi' do
    sequence(:phone_number) { |n| "+5511999#{n.to_s.rjust(6, '0')}" }
    provider_config do
      {
        'api_url' => 'https://test.uazapi.com',
        'api_token' => 'test-token-123'
      }
    end
    account

    after(:build) do |channel|
      channel.class.skip_callback(:commit, :after, :verify_api_connection, raise: false)
      channel.class.skip_callback(:commit, :after, :trigger_initial_sync, raise: false)
    end

    trait :with_sync_completed do
      provider_config do
        {
          'api_url' => 'https://test.uazapi.com',
          'api_token' => 'test-token-123',
          'sync_status' => 'completed',
          'sync_progress' => { 'synced' => 100, 'total' => 100 }
        }
      end
    end

    trait :syncing do
      provider_config do
        {
          'api_url' => 'https://test.uazapi.com',
          'api_token' => 'test-token-123',
          'sync_status' => 'syncing',
          'sync_progress' => { 'synced' => 50, 'total' => 100 }
        }
      end
    end
  end
end
