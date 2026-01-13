require 'rails_helper'

RSpec.describe 'Shop Products API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:category) { create(:shop_category, account: account) }
  let!(:product) { create(:shop_product, account: account, category: category) }

  describe 'GET /api/v1/accounts/{account.id}/shop/products' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/products"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all products' do
        get "/api/v1/accounts/#{account.id}/shop/products",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end

      it 'filters by active_only' do
        create(:shop_product, :inactive, account: account)

        get "/api/v1/accounts/#{account.id}/shop/products",
            headers: admin.create_new_auth_token,
            params: { active_only: true },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end

      it 'filters by category_id' do
        other_category = create(:shop_category, account: account)
        create(:shop_product, account: account, category: other_category)

        get "/api/v1/accounts/#{account.id}/shop/products",
            headers: admin.create_new_auth_token,
            params: { category_id: category.id },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/shop/products/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/products/#{product.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the product' do
        get "/api/v1/accounts/#{account.id}/shop/products/#{product.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['name']).to eq(product.name)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/shop/products' do
    let(:valid_params) do
      {
        product: {
          name: 'New Product',
          price: 99.90,
          description: 'A new product',
          shop_category_id: category.id
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/shop/products", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the product' do
        expect do
          post "/api/v1/accounts/#{account.id}/shop/products",
               headers: admin.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(Shop::Product, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns error for invalid params' do
        post "/api/v1/accounts/#{account.id}/shop/products",
             headers: admin.create_new_auth_token,
             params: { product: { name: '' } },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/shop/products/:id' do
    let(:valid_params) { { product: { name: 'Updated Product' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/shop/products/#{product.id}",
              params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the product' do
        patch "/api/v1/accounts/#{account.id}/shop/products/#{product.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(product.reload.name).to eq('Updated Product')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/shop/products/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/shop/products/#{product.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes the product' do
        expect do
          delete "/api/v1/accounts/#{account.id}/shop/products/#{product.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(Shop::Product, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
