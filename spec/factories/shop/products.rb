# frozen_string_literal: true

FactoryBot.define do
  factory :shop_product, class: 'Shop::Product' do
    account
    sequence(:name) { |n| "Product #{n}" }
    sequence(:slug) { |n| "product-#{n}" }
    description { 'Test product description' }
    price { 99.90 }
    compare_at_price { nil }
    stock_quantity { 10 }
    track_inventory { true }
    active { true }
    featured { false }

    trait :with_category do
      association :category, factory: :shop_category
    end

    trait :on_sale do
      price { 79.90 }
      compare_at_price { 99.90 }
    end

    trait :out_of_stock do
      stock_quantity { 0 }
    end

    trait :featured do
      featured { true }
    end

    trait :inactive do
      active { false }
    end

    trait :no_inventory_tracking do
      track_inventory { false }
    end
  end
end
