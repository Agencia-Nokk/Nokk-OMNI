# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::ReadApiDocumentationService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }
  let(:url) { 'https://viacep.com.br/docs' }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('read_api_documentation')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('Read API documentation')
    end
  end

  describe '#parameters' do
    it 'defines url and focus parameters' do
      expect(service.parameters.keys).to contain_exactly(:url, :focus)
    end
  end

  describe '#active?' do
    it 'always returns true (Jina check happens in execute)' do
      expect(service.active?).to be true
    end
  end

  describe '#execute' do
    context 'when URL is blank' do
      it 'returns error message for nil' do
        expect(service.execute(url: nil)).to eq('URL is required')
      end

      it 'returns error message for empty string' do
        expect(service.execute(url: '')).to eq('URL is required')
      end
    end

    context 'when Jina API key is not configured' do
      let(:jina_service) { instance_double(Captain::Tools::JinaReaderService, active?: false) }

      before do
        allow(Captain::Tools::JinaReaderService).to receive(:new).and_return(jina_service)
      end

      it 'returns configuration message' do
        result = service.execute(url: url)
        expect(result).to include('JINA_API_KEY is not configured')
      end
    end

    context 'when reading is successful' do
      let(:jina_service) { instance_double(Captain::Tools::JinaReaderService, active?: true) }
      let(:doc_content) { '# ViaCEP API\n\nEndpoint: GET /ws/{cep}/json/' }

      before do
        allow(Captain::Tools::JinaReaderService).to receive(:new).and_return(jina_service)
        allow(jina_service).to receive(:read_url).and_return(doc_content)
      end

      it 'returns the documentation content' do
        result = service.execute(url: url)
        expect(result).to be_a(Hash)
        expect(result['content']).to include('ViaCEP')
      end

      it 'includes the source URL' do
        result = service.execute(url: url)
        expect(result['content']).to include(url)
      end
    end

    context 'when reading fails' do
      let(:jina_service) { instance_double(Captain::Tools::JinaReaderService, active?: true) }

      before do
        allow(Captain::Tools::JinaReaderService).to receive(:new).and_return(jina_service)
        allow(jina_service).to receive(:read_url).and_raise(
          Captain::Tools::JinaReaderService::JinaError.new('Connection timeout')
        )
      end

      it 'returns error message' do
        result = service.execute(url: url)
        expect(result).to include('Failed')
        expect(result).to include('Connection timeout')
      end
    end
  end
end
