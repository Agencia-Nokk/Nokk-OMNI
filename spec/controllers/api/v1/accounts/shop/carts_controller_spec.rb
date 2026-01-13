require 'rails_helper'

RSpec.describe 'Shop Carts API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:contact) { create(:contact, account: account) }
  let!(:product) { create(:shop_product, account: account, price: 50.0) }
  let!(:cart) { create(:shop_cart, account: account, contact: contact) }

  describe 'GET /api/v1/accounts/{account.id}/shop/carts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/carts"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all active carts' do
        get "/api/v1/accounts/#{account.id}/shop/carts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/shop/carts/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the cart' do
        get "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/shop/carts' do
    let(:valid_params) { { cart: { contact_id: contact.id } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/shop/carts", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates a new cart' do
        expect do
          post "/api/v1/accounts/#{account.id}/shop/carts",
               headers: admin.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(Shop::Cart, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/shop/carts/:id/add_item' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/add_item",
             params: { product_id: product.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'adds item to cart' do
        expect do
          post "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/add_item",
               headers: admin.create_new_auth_token,
               params: { product_id: product.id, quantity: 2 },
               as: :json
        end.to change(Shop::CartItem, :count).by(1)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['cart']['subtotal'].to_f).to eq(100.0)
      end

      it 'increments quantity for existing item' do
        cart.add_item(product, quantity: 1)

        post "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/add_item",
             headers: admin.create_new_auth_token,
             params: { product_id: product.id, quantity: 2 },
             as: :json

        expect(cart.items.first.reload.quantity).to eq(3)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/shop/carts/:id/items/:item_id' do
    let!(:cart_item) { cart.add_item(product, quantity: 1) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/items/#{cart_item.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'removes item from cart' do
        expect do
          delete "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/items/#{cart_item.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(Shop::CartItem, :count).by(-1)

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/shop/carts/:id/items/:item_id' do
    let!(:cart_item) { cart.add_item(product, quantity: 1) }

    context 'when it is an authenticated user' do
      it 'updates item quantity' do
        patch "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/items/#{cart_item.id}",
              headers: admin.create_new_auth_token,
              params: { quantity: 5 },
              as: :json

        expect(response).to have_http_status(:success)
        expect(cart_item.reload.quantity).to eq(5)
      end

      it 'removes item when quantity is zero' do
        expect do
          patch "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/items/#{cart_item.id}",
                headers: admin.create_new_auth_token,
                params: { quantity: 0 },
                as: :json
        end.to change(Shop::CartItem, :count).by(-1)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/shop/carts/:id/convert_to_order' do
    before { cart.add_item(product, quantity: 2) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/convert_to_order"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'converts cart to order' do
        expect do
          post "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}/convert_to_order",
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Shop::Order, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(cart.reload.status).to eq('converted')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/shop/carts/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes the cart' do
        expect do
          delete "/api/v1/accounts/#{account.id}/shop/carts/#{cart.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(Shop::Cart, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
