require 'rails_helper'

RSpec.describe 'Shop Orders API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:contact) { create(:contact, account: account) }
  let!(:product) { create(:shop_product, account: account) }
  let!(:order) { create(:shop_order, account: account, contact: contact) }

  before do
    create(:shop_order_item, order: order, product: product)
  end

  describe 'GET /api/v1/accounts/{account.id}/shop/orders' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/orders"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all orders' do
        get "/api/v1/accounts/#{account.id}/shop/orders",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end

      it 'filters by status' do
        create(:shop_order, :confirmed, account: account, contact: contact)

        get "/api/v1/accounts/#{account.id}/shop/orders",
            headers: admin.create_new_auth_token,
            params: { status: 'pending' },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/shop/orders/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the order' do
        get "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['order_number']).to eq(order.order_number)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/shop/orders/:id' do
    let(:valid_params) { { order: { internal_notes: 'Updated notes' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}",
              params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the order' do
        patch "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(order.reload.internal_notes).to eq('Updated notes')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/shop/orders/:id/confirm' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}/confirm"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'confirms the order' do
        post "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}/confirm",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(order.reload.status).to eq('confirmed')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/shop/orders/:id/cancel' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}/cancel"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'cancels the order' do
        post "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}/cancel",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(order.reload.status).to eq('cancelled')
      end

      it 'restores product stock when cancelled' do
        initial_stock = product.stock_quantity
        order_quantity = order.items.first.quantity

        post "/api/v1/accounts/#{account.id}/shop/orders/#{order.id}/cancel",
             headers: admin.create_new_auth_token,
             as: :json

        expect(product.reload.stock_quantity).to eq(initial_stock + order_quantity)
      end
    end
  end
end
