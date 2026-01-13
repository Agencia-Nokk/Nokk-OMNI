# frozen_string_literal: true

FactoryBot.define do
  factory :shop_cart, class: 'Shop::Cart' do
    account
    conversation { nil }
    contact { nil }
    status { 'active' }
    metadata { {} }

    trait :with_contact do
      association :contact
    end

    trait :with_conversation do
      association :conversation
    end

    trait :converted do
      status { 'converted' }
    end

    trait :abandoned do
      status { 'abandoned' }
    end
  end
end
