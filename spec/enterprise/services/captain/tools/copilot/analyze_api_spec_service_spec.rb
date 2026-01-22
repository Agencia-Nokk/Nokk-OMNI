# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::AnalyzeApiSpecService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('analyze_api_spec')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('Prepare API documentation')
    end
  end

  describe '#parameters' do
    it 'defines documentation and desired_functionality parameters' do
      expect(service.parameters.keys).to contain_exactly(:documentation, :desired_functionality)
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
    let(:documentation) do
      <<~DOC
        # ViaCEP API

        ## Endpoint
        GET https://viacep.com.br/ws/{cep}/json/

        ## Parameters
        - cep: CEP code (8 digits)

        ## Response
        { "logradouro": "...", "bairro": "...", "localidade": "..." }
      DOC
    end

    context 'when documentation is blank' do
      it 'returns error message' do
        result = service.execute(documentation: nil, desired_functionality: 'lookup CEP')
        expect(result).to eq('Documentation content is required')
      end
    end

    context 'when desired_functionality is blank' do
      it 'returns error message' do
        result = service.execute(documentation: documentation, desired_functionality: nil)
        expect(result).to eq('Desired functionality description is required')
      end
    end

    context 'when both parameters are provided' do
      it 'returns analysis instructions with documentation' do
        result = service.execute(documentation: documentation, desired_functionality: 'lookup CEP addresses')
        expect(result).to be_a(Hash)
        expect(result['content']).to include('lookup CEP addresses')
        expect(result['content']).to include('Analysis Instructions')
        expect(result['content']).to include('Endpoint URL')
        expect(result['content']).to include('HTTP Method')
        expect(result['content']).to include('Parameters')
      end

      it 'includes the original documentation' do
        result = service.execute(documentation: documentation, desired_functionality: 'lookup CEP')
        expect(result['content']).to include('ViaCEP API')
      end
    end
  end
end
