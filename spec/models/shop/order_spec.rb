require 'rails_helper'

RSpec.describe Shop::Order do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation).optional }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:items).class_name('Shop::OrderItem').dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:shop_order, account: account, contact: contact) }

    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account) }

    it { is_expected.to validate_presence_of(:order_number) }

    it 'validates uniqueness of order_number scoped to account' do
      create(:shop_order, account: account, contact: contact, order_number: 'ORDER-001')
      duplicate_order = build(:shop_order, account: account, contact: contact, order_number: 'ORDER-001')

      expect(duplicate_order).not_to be_valid
      expect(duplicate_order.errors[:order_number]).to include('has already been taken')
    end

    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending confirmed processing shipped delivered cancelled]) }
    it { is_expected.to validate_presence_of(:subtotal) }
    it { is_expected.to validate_presence_of(:total) }
    it { is_expected.to validate_numericality_of(:subtotal).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account) }

    describe '.recent' do
      it 'returns orders in descending order by created_at' do
        old_order = create(:shop_order, account: account, contact: contact, created_at: 2.days.ago)
        new_order = create(:shop_order, account: account, contact: contact, created_at: 1.day.ago)

        expect(described_class.recent).to eq([new_order, old_order])
      end
    end

    describe '.by_status' do
      it 'returns orders filtered by status' do
        pending_order = create(:shop_order, account: account, contact: contact, status: 'pending')
        create(:shop_order, :confirmed, account: account, contact: contact)

        expect(described_class.by_status('pending')).to eq([pending_order])
      end
    end

    describe '.pending' do
      it 'returns only pending orders' do
        pending_order = create(:shop_order, account: account, contact: contact)
        create(:shop_order, :confirmed, account: account, contact: contact)

        expect(described_class.pending).to eq([pending_order])
      end
    end
  end

  describe '.generate_order_number' do
    let(:account) { create(:account) }

    it 'generates order number with date prefix' do
      order_number = described_class.generate_order_number(account)

      expect(order_number).to match(/^\d{8}-\d{4}$/)
      expect(order_number).to start_with(Time.current.strftime('%Y%m%d'))
    end

    it 'increments sequence for same day orders' do
      contact = create(:contact, account: account)
      create(:shop_order, account: account, contact: contact, order_number: "#{Time.current.strftime('%Y%m%d')}-0001")

      order_number = described_class.generate_order_number(account)

      expect(order_number).to end_with('-0002')
    end
  end

  describe '#confirm!' do
    it 'updates status to confirmed' do
      order = create(:shop_order)

      order.confirm!

      expect(order.reload.status).to eq('confirmed')
    end
  end

  describe '#cancel!' do
    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account) }
    let(:product) { create(:shop_product, account: account, stock_quantity: 10, track_inventory: true) }
    let(:order) { create(:shop_order, account: account, contact: contact) }

    before do
      create(:shop_order_item, order: order, product: product, quantity: 2)
    end

    it 'updates status to cancelled' do
      order.cancel!

      expect(order.reload.status).to eq('cancelled')
    end

    it 'restores product stock' do
      order.cancel!

      expect(product.reload.stock_quantity).to eq(12)
    end

    context 'with variant' do
      let(:variant) { create(:shop_product_variant, product: product, stock_quantity: 5) }
      let(:new_order) { create(:shop_order, account: account, contact: contact) }

      before do
        create(:shop_order_item, order: new_order, product: product, variant: variant, quantity: 2)
      end

      it 'restores variant stock' do
        new_order.cancel!

        expect(variant.reload.stock_quantity).to eq(7)
      end
    end
  end

  describe '#total_items' do
    let(:order) { create(:shop_order) }

    it 'returns sum of item quantities' do
      create(:shop_order_item, order: order, quantity: 2)
      create(:shop_order_item, order: order, quantity: 3)

      expect(order.total_items).to eq(5)
    end
  end
end
