require 'rails_helper'

RSpec.describe Shop::ProductVariant do
  let(:product) { create(:shop_product) }

  describe 'associations' do
    it 'belongs to product' do
      variant = build(:shop_product_variant, product: product)
      expect(variant.product).to eq(product)
    end

    it 'has many cart_items' do
      variant = create(:shop_product_variant, product: product)
      expect(variant).to respond_to(:cart_items)
    end

    it 'has many order_items' do
      variant = create(:shop_product_variant, product: product)
      expect(variant).to respond_to(:order_items)
    end
  end

  describe 'validations' do
    subject { build(:shop_product_variant, product: product) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:stock_quantity).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let(:product) { create(:shop_product) }

    describe '.active' do
      it 'returns only active variants' do
        active_variant = create(:shop_product_variant, product: product, active: true)
        create(:shop_product_variant, :inactive, product: product)

        expect(described_class.active).to eq([active_variant])
      end
    end

    describe '.in_stock' do
      it 'returns only variants with stock' do
        in_stock = create(:shop_product_variant, product: product, stock_quantity: 5)
        create(:shop_product_variant, :out_of_stock, product: product)

        expect(described_class.in_stock).to eq([in_stock])
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_sku' do
      it 'generates sku from product sku when blank' do
        product = create(:shop_product, sku: 'PROD-12345678')
        variant = build(:shop_product_variant, product: product, sku: nil)
        variant.valid?

        expect(variant.sku).to match(/^PROD-12345678-[A-F0-9]{4}$/)
      end
    end
  end

  describe '#in_stock?' do
    it 'returns true when stock_quantity is positive' do
      variant = build(:shop_product_variant, stock_quantity: 5)

      expect(variant.in_stock?).to be true
    end

    it 'returns false when stock_quantity is zero' do
      variant = build(:shop_product_variant, stock_quantity: 0)

      expect(variant.in_stock?).to be false
    end
  end

  describe '#final_price' do
    let(:product) { create(:shop_product, price: 99.90) }

    it 'returns variant price when set' do
      variant = build(:shop_product_variant, :with_price, product: product)

      expect(variant.final_price).to eq(109.90)
    end

    it 'returns product price when variant price is nil' do
      variant = build(:shop_product_variant, product: product, price: nil)

      expect(variant.final_price).to eq(99.90)
    end
  end
end
