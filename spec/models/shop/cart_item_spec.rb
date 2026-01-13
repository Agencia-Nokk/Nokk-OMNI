require 'rails_helper'

RSpec.describe Shop::CartItem do
  describe 'associations' do
    it { is_expected.to belong_to(:cart).class_name('Shop::Cart') }
    it { is_expected.to belong_to(:product).class_name('Shop::Product') }
    it { is_expected.to belong_to(:variant).class_name('Shop::ProductVariant').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:unit_price) }
    it { is_expected.to validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
  end

  describe '#total_price' do
    it 'calculates correct total price' do
      cart_item = build(:shop_cart_item, unit_price: 25.50, quantity: 3)

      expect(cart_item.total_price).to eq(76.50)
    end
  end

  describe '#display_name' do
    let(:product) { create(:shop_product, name: 'Test Product') }

    it 'returns product name when no variant' do
      cart_item = build(:shop_cart_item, product: product, variant: nil)

      expect(cart_item.display_name).to eq('Test Product')
    end

    it 'returns product and variant name when variant present' do
      variant = create(:shop_product_variant, product: product, name: 'Large')
      cart_item = build(:shop_cart_item, product: product, variant: variant)

      expect(cart_item.display_name).to eq('Test Product - Large')
    end
  end
end
