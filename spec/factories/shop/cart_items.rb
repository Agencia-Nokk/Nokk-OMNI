# frozen_string_literal: true

FactoryBot.define do
  factory :shop_cart_item, class: 'Shop::CartItem' do
    association :cart, factory: :shop_cart
    association :product, factory: :shop_product
    variant { nil }
    quantity { 1 }
    unit_price { 99.90 }
    metadata { {} }

    trait :with_variant do
      association :variant, factory: :shop_product_variant
    end
  end
end
