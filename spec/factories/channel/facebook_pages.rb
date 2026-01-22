# frozen_string_literal: true

FactoryBot.define do
  factory :channel_facebook_page, class: 'Channel::FacebookPage' do
    page_access_token { SecureRandom.uuid }
    user_access_token { SecureRandom.uuid }
    page_id { SecureRandom.uuid }
    inbox
    account

    before :create do |_channel|
      WebMock::API.stub_request(:post, %r{https://graph\.facebook\.com/v\d+\.\d+/me/subscribed_apps})
    end
  end
end
