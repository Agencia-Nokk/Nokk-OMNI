# frozen_string_literal: true

FactoryBot.define do
  factory :shop_order_item, class: 'Shop::OrderItem' do
    association :order, factory: :shop_order
    association :product, factory: :shop_product
    variant { nil }
    product_name { 'Test Product' }
    variant_name { nil }
    quantity { 2 }
    unit_price { 99.90 }
    total_price { 199.80 }
    metadata { {} }

    trait :with_variant do
      association :variant, factory: :shop_product_variant
      variant_name { 'Test Variant' }
    end
  end
end
