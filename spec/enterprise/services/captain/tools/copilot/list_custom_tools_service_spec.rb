# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::ListCustomToolsService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('list_custom_tools')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('List all custom HTTP tools')
    end
  end

  describe '#parameters' do
    it 'defines enabled_only and search parameters' do
      expect(service.parameters.keys).to contain_exactly(:enabled_only, :search)
    end
  end

  describe '#active?' do
    context 'when user is an admin' do
      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user is an agent' do
      let(:user) { create(:user, account: account) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end
  end

  describe '#execute' do
    context 'when no tools exist' do
      it 'returns no tools message' do
        result = service.execute
        expect(result).to include('No custom tools found')
      end
    end

    context 'when tools exist' do
      let!(:tool1) { create(:captain_custom_tool, account: account, title: 'ViaCEP Lookup', enabled: true) }
      let!(:tool2) { create(:captain_custom_tool, account: account, title: 'CNPJ Query', enabled: false) }

      it 'returns all tools' do
        result = service.execute
        expect(result).to be_a(Hash)
        expect(result['content']).to include('2 custom tool(s)')
        expect(result['content']).to include('ViaCEP Lookup')
        expect(result['content']).to include('CNPJ Query')
      end

      it 'returns entities for each tool' do
        result = service.execute
        expect(result['entities']).to be_an(Array)
        expect(result['entities'].length).to eq(2)
      end

      context 'with enabled_only filter' do
        it 'returns only enabled tools' do
          result = service.execute(enabled_only: true)
          expect(result['content']).to include('1 custom tool(s)')
          expect(result['content']).to include('ViaCEP Lookup')
          expect(result['content']).not_to include('CNPJ Query')
        end
      end

      context 'with search filter' do
        it 'filters by title' do
          result = service.execute(search: 'viacep')
          expect(result['content']).to include('ViaCEP Lookup')
          expect(result['content']).not_to include('CNPJ Query')
        end

        it 'filters by description' do
          tool1.update(description: 'Brazilian postal code lookup')
          result = service.execute(search: 'postal')
          expect(result['content']).to include('ViaCEP Lookup')
        end
      end
    end

    context 'when tools belong to different accounts' do
      let(:other_account) { create(:account) }
      let!(:own_tool) { create(:captain_custom_tool, account: account, title: 'Own Tool') }
      let!(:other_tool) { create(:captain_custom_tool, account: other_account, title: 'Other Tool') }

      it 'only returns tools from the current account' do
        result = service.execute
        expect(result['content']).to include('Own Tool')
        expect(result['content']).not_to include('Other Tool')
      end
    end
  end
end
