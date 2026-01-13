# frozen_string_literal: true

FactoryBot.define do
  factory :shop_category, class: 'Shop::Category' do
    account
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    description { 'Test category description' }
    position { 0 }
    active { true }
  end
end
