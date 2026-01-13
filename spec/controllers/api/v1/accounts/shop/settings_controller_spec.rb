require 'rails_helper'

RSpec.describe 'Shop Settings API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/shop/settings' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/shop/settings"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the shop settings' do
        get "/api/v1/accounts/#{account.id}/shop/settings",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end

      it 'creates shop settings if not exists' do
        expect do
          get "/api/v1/accounts/#{account.id}/shop/settings",
              headers: admin.create_new_auth_token,
              as: :json
        end.to change(Shop::Setting, :count).by(1)
      end

      it 'returns existing shop settings' do
        create(:shop_setting, account: account, name: 'My Shop')

        get "/api/v1/accounts/#{account.id}/shop/settings",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['name']).to eq('My Shop')
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/shop/settings' do
    let(:valid_params) do
      {
        setting: {
          name: 'Updated Shop Name',
          description: 'Updated description',
          enabled: true,
          primary_color: '#FF5733'
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/shop/settings",
              params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the shop settings' do
        patch "/api/v1/accounts/#{account.id}/shop/settings",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['name']).to eq('Updated Shop Name')
      end

      it 'returns error for invalid params' do
        patch "/api/v1/accounts/#{account.id}/shop/settings",
              headers: admin.create_new_auth_token,
              params: { setting: { primary_color: 'invalid' } },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'updates whatsapp number' do
        patch "/api/v1/accounts/#{account.id}/shop/settings",
              headers: admin.create_new_auth_token,
              params: { setting: { whatsapp_number: '+5511999999999' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(account.shop_setting.reload.whatsapp_number).to eq('+5511999999999')
      end

      it 'updates customization fields' do
        patch "/api/v1/accounts/#{account.id}/shop/settings",
              headers: admin.create_new_auth_token,
              params: {
                setting: {
                  header_style: 'with_banner',
                  card_style: 'border',
                  products_per_row: 4
                }
              },
              as: :json

        expect(response).to have_http_status(:success)
        setting = account.shop_setting.reload
        expect(setting.header_style).to eq('with_banner')
        expect(setting.card_style).to eq('border')
        expect(setting.products_per_row).to eq(4)
      end
    end
  end
end
