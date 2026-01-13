# frozen_string_literal: true

FactoryBot.define do
  factory :shop_order, class: 'Shop::Order' do
    account
    association :contact
    conversation { nil }
    user { nil }
    sequence(:order_number) { |n| "#{Time.current.strftime('%Y%m%d')}-#{n.to_s.rjust(4, '0')}" }
    status { 'pending' }
    subtotal { 199.80 }
    discount { 0.0 }
    total { 199.80 }
    customer_notes { nil }
    internal_notes { nil }
    metadata { {} }

    trait :confirmed do
      status { 'confirmed' }
    end

    trait :processing do
      status { 'processing' }
    end

    trait :shipped do
      status { 'shipped' }
    end

    trait :delivered do
      status { 'delivered' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :with_discount do
      discount { 20.0 }
      total { 179.80 }
    end
  end
end
