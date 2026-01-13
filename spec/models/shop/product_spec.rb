require 'rails_helper'

RSpec.describe Shop::Product do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:category).class_name('Shop::Category').optional }
    it { is_expected.to have_many(:variants).class_name('Shop::ProductVariant').dependent(:destroy) }
    it { is_expected.to have_many(:cart_items).class_name('Shop::CartItem').dependent(:destroy) }
    it { is_expected.to have_many(:order_items).class_name('Shop::OrderItem').dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:shop_product) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:account_id) }

    context 'when track_inventory is true' do
      before { subject.track_inventory = true }

      it { is_expected.to validate_numericality_of(:stock_quantity).only_integer.is_greater_than_or_equal_to(0) }
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }

    describe '.active' do
      it 'returns only active products' do
        active_product = create(:shop_product, account: account, active: true)
        create(:shop_product, :inactive, account: account)

        expect(described_class.active).to eq([active_product])
      end
    end

    describe '.in_stock' do
      it 'returns products in stock or without inventory tracking' do
        in_stock = create(:shop_product, account: account, stock_quantity: 5)
        no_tracking = create(:shop_product, :no_inventory_tracking, account: account, stock_quantity: 0)
        create(:shop_product, :out_of_stock, account: account)

        expect(described_class.in_stock).to contain_exactly(in_stock, no_tracking)
      end
    end

    describe '.featured' do
      it 'returns only featured products' do
        featured = create(:shop_product, :featured, account: account)
        create(:shop_product, account: account)

        expect(described_class.featured).to eq([featured])
      end
    end

    describe '.by_category' do
      it 'returns products by category' do
        category = create(:shop_category, account: account)
        product_with_category = create(:shop_product, account: account, category: category)
        create(:shop_product, account: account)

        expect(described_class.by_category(category.id)).to eq([product_with_category])
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_slug' do
      it 'generates slug from name when blank' do
        product = build(:shop_product, name: 'Test Product Name', slug: nil)
        product.valid?

        expect(product.slug).to eq('test-product-name')
      end

      it 'does not override existing slug' do
        product = build(:shop_product, name: 'Test Product', slug: 'custom-slug')
        product.valid?

        expect(product.slug).to eq('custom-slug')
      end
    end

    describe '#generate_sku' do
      it 'generates sku when blank' do
        product = build(:shop_product, sku: nil)
        product.valid?

        expect(product.sku).to match(/^PROD-[A-F0-9]{8}$/)
      end
    end
  end

  describe '#in_stock?' do
    it 'returns true when stock_quantity is positive' do
      product = build(:shop_product, stock_quantity: 5, track_inventory: true)

      expect(product.in_stock?).to be true
    end

    it 'returns false when stock_quantity is zero and tracking inventory' do
      product = build(:shop_product, stock_quantity: 0, track_inventory: true)

      expect(product.in_stock?).to be false
    end

    it 'returns true when not tracking inventory' do
      product = build(:shop_product, stock_quantity: 0, track_inventory: false)

      expect(product.in_stock?).to be true
    end
  end

  describe '#on_sale?' do
    it 'returns true when compare_at_price is greater than price' do
      product = build(:shop_product, :on_sale)

      expect(product.on_sale?).to be true
    end

    it 'returns false when compare_at_price is nil' do
      product = build(:shop_product, compare_at_price: nil)

      expect(product.on_sale?).to be false
    end

    it 'returns false when compare_at_price is less than price' do
      product = build(:shop_product, price: 100, compare_at_price: 80)

      expect(product.on_sale?).to be false
    end
  end

  describe '#discount_percentage' do
    it 'returns correct discount percentage' do
      product = build(:shop_product, price: 80, compare_at_price: 100)

      expect(product.discount_percentage).to eq(20)
    end

    it 'returns 0 when not on sale' do
      product = build(:shop_product, compare_at_price: nil)

      expect(product.discount_percentage).to eq(0)
    end
  end
end
