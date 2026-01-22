# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetCustomToolService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('get_custom_tool')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('Get detailed information')
    end
  end

  describe '#parameters' do
    it 'defines tool_id, slug, and title parameters' do
      expect(service.parameters.keys).to contain_exactly(:tool_id, :slug, :title)
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
    context 'when no identifier is provided' do
      it 'returns error message' do
        result = service.execute
        expect(result).to include('at least one of')
      end
    end

    context 'when tool is not found' do
      it 'returns not found message for tool_id' do
        result = service.execute(tool_id: 999)
        expect(result).to include('not found')
      end

      it 'returns not found message for slug' do
        result = service.execute(slug: 'nonexistent')
        expect(result).to include('not found')
      end

      it 'returns not found message for title' do
        result = service.execute(title: 'Nonexistent Tool')
        expect(result).to include('not found')
      end
    end

    context 'when tool exists' do
      let!(:tool) do
        create(:captain_custom_tool, :with_params, :with_bearer_auth,
               account: account,
               title: 'ViaCEP Lookup',
               endpoint_url: 'https://viacep.com.br/ws/{{ cep }}/json/')
      end

      it 'finds tool by ID' do
        result = service.execute(tool_id: tool.id)
        expect(result).to be_a(Hash)
        expect(result['content']).to include('ViaCEP Lookup')
      end

      it 'finds tool by slug' do
        result = service.execute(slug: tool.slug)
        expect(result['content']).to include('ViaCEP Lookup')
      end

      it 'finds tool by title (case insensitive)' do
        result = service.execute(title: 'viacep lookup')
        expect(result['content']).to include('ViaCEP Lookup')
      end

      it 'returns full tool details' do
        result = service.execute(tool_id: tool.id)
        content = result['content']

        expect(content).to include('ID:')
        expect(content).to include('Slug:')
        expect(content).to include('Status:')
        expect(content).to include('Endpoint')
        expect(content).to include('Authentication')
        expect(content).to include('Parameters')
      end

      it 'returns entity with full details' do
        result = service.execute(tool_id: tool.id)
        expect(result['entities']).to be_an(Array)
        expect(result['entities'].first['type']).to eq('custom_tool')
      end
    end

    context 'when tool belongs to different account' do
      let(:other_account) { create(:account) }
      let!(:other_tool) { create(:captain_custom_tool, account: other_account, title: 'Other Tool') }

      it 'returns not found' do
        result = service.execute(tool_id: other_tool.id)
        expect(result).to include('not found')
      end
    end
  end
end
