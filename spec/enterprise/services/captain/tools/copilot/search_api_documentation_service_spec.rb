# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::SearchApiDocumentationService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }
  let(:api_key) { 'test-jina-api-key' }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('search_api_documentation')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('Search the web for API documentation')
    end
  end

  describe '#parameters' do
    it 'defines query and num_results parameters' do
      expect(service.parameters.keys).to contain_exactly(:query, :num_results)
    end
  end

  describe '#active?' do
    it 'always returns true (Jina check happens in execute)' do
      expect(service.active?).to be true
    end
  end

  describe '#execute' do
    let(:jina_search_url) { 'https://s.jina.ai/' }
    let(:search_results) do
      [
        { title: 'ViaCEP API', url: 'https://viacep.com.br', description: 'API de CEP' }
      ]
    end

    context 'when query is blank' do
      it 'returns error message for nil' do
        expect(service.execute(query: nil)).to eq('Search query is required')
      end

      it 'returns error message for empty string' do
        expect(service.execute(query: '')).to eq('Search query is required')
      end
    end

    context 'when Jina API key is not configured' do
      let(:jina_service) { instance_double(Captain::Tools::JinaReaderService, active?: false) }

      before do
        allow(Captain::Tools::JinaReaderService).to receive(:new).and_return(jina_service)
      end

      it 'returns configuration message' do
        result = service.execute(query: 'test query')
        expect(result).to include('JINA_API_KEY is not configured')
      end
    end

    context 'when search is successful' do
      let(:jina_service) { instance_double(Captain::Tools::JinaReaderService, active?: true) }

      before do
        allow(Captain::Tools::JinaReaderService).to receive(:new).and_return(jina_service)
        allow(jina_service).to receive(:search).and_return(search_results)
      end

      it 'returns formatted search results' do
        result = service.execute(query: 'ViaCEP API documentation')
        expect(result).to be_a(Hash)
        expect(result['content']).to include('ViaCEP API')
      end
    end

    context 'when search returns empty results' do
      let(:jina_service) { instance_double(Captain::Tools::JinaReaderService, active?: true) }

      before do
        allow(Captain::Tools::JinaReaderService).to receive(:new).and_return(jina_service)
        allow(jina_service).to receive(:search).and_return([])
      end

      it 'returns no results message' do
        result = service.execute(query: 'nonexistent api xyz')
        expect(result).to include('No results found')
      end
    end

    context 'when search raises an error' do
      let(:jina_service) { instance_double(Captain::Tools::JinaReaderService, active?: true) }

      before do
        allow(Captain::Tools::JinaReaderService).to receive(:new).and_return(jina_service)
        allow(jina_service).to receive(:search).and_raise(
          Captain::Tools::JinaReaderService::JinaError.new('Connection failed')
        )
      end

      it 'returns error message' do
        result = service.execute(query: 'test query')
        expect(result).to include('Search failed')
        expect(result).to include('Connection failed')
      end
    end
  end
end
