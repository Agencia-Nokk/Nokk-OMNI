# frozen_string_literal: true

FactoryBot.define do
  factory :shop_setting, class: 'Shop::Setting' do
    account
    name { 'Test Shop' }
    description { 'Test shop description' }
    whatsapp_number { '+5511999999999' }
    contact_email { 'shop@test.com' }
    business_hours { 'Seg-Sex: 9h-18h' }
    enabled { true }
    show_out_of_stock { true }
    show_prices { true }
    default_sort { 'newest' }
    products_per_page { 12 }
    minimum_order_value { nil }
    primary_color { '#1F93FF' }
    background_color { '#FFFFFF' }
    text_color { '#1F2937' }
    secondary_color { '#6B7280' }
    header_style { 'minimal' }
    card_style { 'shadow' }
    products_per_row { 3 }
    show_categories_bar { true }
    show_featured_badge { true }
    featured_badge_text { 'Destaque' }

    trait :disabled do
      enabled { false }
    end

    trait :with_minimum_order do
      minimum_order_value { 50.0 }
      minimum_order_message { 'Pedido minimo de R$ 50,00' }
    end

    trait :with_banner_style do
      header_style { 'with_banner' }
    end
  end
end
