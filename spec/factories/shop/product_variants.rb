# frozen_string_literal: true

FactoryBot.define do
  factory :shop_product_variant, class: 'Shop::ProductVariant' do
    association :product, factory: :shop_product
    sequence(:name) { |n| "Variant #{n}" }
    price { nil }
    stock_quantity { 5 }
    options { { size: 'M', color: 'Blue' } }
    active { true }

    trait :with_price do
      price { 109.90 }
    end

    trait :out_of_stock do
      stock_quantity { 0 }
    end

    trait :inactive do
      active { false }
    end
  end
end
