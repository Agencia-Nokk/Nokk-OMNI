require 'rails_helper'

RSpec.describe Shop::OrderItem do
  describe 'associations' do
    it { is_expected.to belong_to(:order).class_name('Shop::Order') }
    it { is_expected.to belong_to(:product).class_name('Shop::Product') }
    it { is_expected.to belong_to(:variant).class_name('Shop::ProductVariant').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:product_name) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:unit_price) }
    it { is_expected.to validate_presence_of(:total_price) }
    it { is_expected.to validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total_price).is_greater_than_or_equal_to(0) }
  end

  describe 'callbacks' do
    describe '#set_total_price' do
      it 'calculates total_price before validation' do
        order_item = build(:shop_order_item, unit_price: 25.0, quantity: 4, total_price: nil)
        order_item.valid?

        expect(order_item.total_price).to eq(100.0)
      end
    end
  end

  describe '#display_name' do
    it 'returns product name when no variant' do
      order_item = build(:shop_order_item, product_name: 'Test Product', variant_name: nil)

      expect(order_item.display_name).to eq('Test Product')
    end

    it 'returns product and variant name when variant present' do
      order_item = build(:shop_order_item, product_name: 'Test Product', variant_name: 'Large')

      expect(order_item.display_name).to eq('Test Product - Large')
    end
  end
end
