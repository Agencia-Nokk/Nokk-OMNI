require 'rails_helper'

RSpec.describe Shop::Category do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:products).class_name('Shop::Product').dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:shop_category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:account_id) }
  end

  describe 'scopes' do
    let(:account) { create(:account) }

    describe '.active' do
      it 'returns only active categories' do
        active_category = create(:shop_category, account: account, active: true)
        create(:shop_category, account: account, active: false)

        expect(described_class.active).to eq([active_category])
      end
    end

    describe '.ordered' do
      it 'returns categories ordered by position and name' do
        category_c = create(:shop_category, account: account, position: 1, name: 'C Category')
        category_a = create(:shop_category, account: account, position: 0, name: 'A Category')
        category_b = create(:shop_category, account: account, position: 0, name: 'B Category')

        expect(described_class.ordered).to eq([category_a, category_b, category_c])
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_slug' do
      it 'generates slug from name when blank' do
        category = build(:shop_category, name: 'Test Category', slug: nil)
        category.valid?

        expect(category.slug).to eq('test-category')
      end

      it 'does not override existing slug' do
        category = build(:shop_category, name: 'Test Category', slug: 'custom-slug')
        category.valid?

        expect(category.slug).to eq('custom-slug')
      end
    end
  end

  describe 'products association' do
    it 'nullifies product category when category is destroyed' do
      category = create(:shop_category)
      product = create(:shop_product, category: category, account: category.account)

      category.destroy

      expect(product.reload.category).to be_nil
    end
  end
end
