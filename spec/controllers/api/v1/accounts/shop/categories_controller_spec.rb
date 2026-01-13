require 'rails_helper'

RSpec.describe 'Shop Categories API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:category) { create(:shop_category, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/shop/categories' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/categories"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all categories' do
        get "/api/v1/accounts/#{account.id}/shop/categories",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end

      it 'filters by active_only' do
        create(:shop_category, account: account, active: false)

        get "/api/v1/accounts/#{account.id}/shop/categories",
            headers: admin.create_new_auth_token,
            params: { active_only: true },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/shop/categories/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/categories/#{category.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the category' do
        get "/api/v1/accounts/#{account.id}/shop/categories/#{category.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['name']).to eq(category.name)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/shop/categories' do
    let(:valid_params) do
      {
        category: {
          name: 'New Category',
          description: 'A new category'
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/shop/categories", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the category' do
        expect do
          post "/api/v1/accounts/#{account.id}/shop/categories",
               headers: admin.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(Shop::Category, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns error for invalid params' do
        post "/api/v1/accounts/#{account.id}/shop/categories",
             headers: admin.create_new_auth_token,
             params: { category: { name: '' } },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/shop/categories/:id' do
    let(:valid_params) { { category: { name: 'Updated Category' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/shop/categories/#{category.id}",
              params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the category' do
        patch "/api/v1/accounts/#{account.id}/shop/categories/#{category.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(category.reload.name).to eq('Updated Category')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/shop/categories/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/shop/categories/#{category.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes the category' do
        expect do
          delete "/api/v1/accounts/#{account.id}/shop/categories/#{category.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(Shop::Category, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
