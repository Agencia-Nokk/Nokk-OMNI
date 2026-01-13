require 'rails_helper'

RSpec.describe Shop::Cart do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation).optional }
    it { is_expected.to belong_to(:contact).optional }
    it { is_expected.to have_many(:items).class_name('Shop::CartItem').dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active converted abandoned]) }
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active carts' do
        active_cart = create(:shop_cart, status: 'active')
        create(:shop_cart, :converted)
        create(:shop_cart, :abandoned)

        expect(described_class.active).to eq([active_cart])
      end
    end
  end

  describe '#add_item' do
    let(:cart) { create(:shop_cart) }
    let(:product) { create(:shop_product, price: 50.0, account: cart.account) }

    it 'creates a new cart item' do
      expect { cart.add_item(product, quantity: 2) }.to change { cart.items.count }.by(1)
    end

    it 'sets correct unit price' do
      item = cart.add_item(product, quantity: 1)

      expect(item.unit_price).to eq(50.0)
    end

    it 'increments quantity for existing item' do
      cart.add_item(product, quantity: 1)
      cart.add_item(product, quantity: 2)

      expect(cart.items.count).to eq(1)
      expect(cart.items.first.quantity).to eq(3)
    end

    context 'with variant' do
      let(:variant) { create(:shop_product_variant, :with_price, product: product) }

      it 'uses variant price' do
        item = cart.add_item(product, quantity: 1, variant: variant)

        expect(item.unit_price).to eq(variant.final_price)
      end

      it 'treats different variants as separate items' do
        variant2 = create(:shop_product_variant, product: product)

        cart.add_item(product, quantity: 1, variant: variant)
        cart.add_item(product, quantity: 1, variant: variant2)

        expect(cart.items.count).to eq(2)
      end
    end
  end

  describe '#remove_item' do
    let(:cart) { create(:shop_cart) }
    let(:product) { create(:shop_product, account: cart.account) }

    it 'removes the item from cart' do
      item = cart.add_item(product)

      expect { cart.remove_item(item.id) }.to change { cart.items.count }.by(-1)
    end
  end

  describe '#update_item_quantity' do
    let(:cart) { create(:shop_cart) }
    let(:product) { create(:shop_product, account: cart.account) }

    it 'updates item quantity' do
      item = cart.add_item(product, quantity: 1)
      cart.update_item_quantity(item.id, 5)

      expect(item.reload.quantity).to eq(5)
    end

    it 'removes item when quantity is zero or negative' do
      item = cart.add_item(product, quantity: 1)

      expect { cart.update_item_quantity(item.id, 0) }.to change { cart.items.count }.by(-1)
    end
  end

  describe '#subtotal' do
    let(:cart) { create(:shop_cart) }

    it 'calculates correct subtotal' do
      product1 = create(:shop_product, price: 50.0, account: cart.account)
      product2 = create(:shop_product, price: 30.0, account: cart.account)

      cart.add_item(product1, quantity: 2)
      cart.add_item(product2, quantity: 1)

      expect(cart.subtotal).to eq(130.0)
    end
  end

  describe '#total_items' do
    let(:cart) { create(:shop_cart) }

    it 'returns total quantity of items' do
      product1 = create(:shop_product, account: cart.account)
      product2 = create(:shop_product, account: cart.account)

      cart.add_item(product1, quantity: 2)
      cart.add_item(product2, quantity: 3)

      expect(cart.total_items).to eq(5)
    end
  end

  describe '#convert_to_order!' do
    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account) }
    let(:cart) { create(:shop_cart, account: account, contact: contact) }
    let(:product) { create(:shop_product, price: 50.0, account: account) }

    before { cart.add_item(product, quantity: 2) }

    it 'creates an order' do
      expect { cart.convert_to_order! }.to change { Shop::Order.count }.by(1)
    end

    it 'creates order items' do
      expect { cart.convert_to_order! }.to change { Shop::OrderItem.count }.by(1)
    end

    it 'sets cart status to converted' do
      cart.convert_to_order!

      expect(cart.reload.status).to eq('converted')
    end

    it 'returns the created order' do
      order = cart.convert_to_order!

      expect(order).to be_a(Shop::Order)
      expect(order.total).to eq(100.0)
    end

    it 'copies cart item details to order item' do
      order = cart.convert_to_order!
      order_item = order.items.first

      expect(order_item.product_name).to eq(product.name)
      expect(order_item.quantity).to eq(2)
      expect(order_item.unit_price).to eq(50.0)
    end
  end
end
