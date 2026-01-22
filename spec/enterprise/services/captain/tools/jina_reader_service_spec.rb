# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::JinaReaderService do
  let(:api_key) { 'test-jina-api-key' }
  let(:url) { 'https://example.com/docs' }
  let(:query) { 'API documentation example' }

  describe '#initialize' do
    context 'when API key is configured' do
      it 'initializes successfully' do
        with_modified_env(JINA_API_KEY: api_key) do
          expect { described_class.new }.not_to raise_error
        end
      end
    end

    context 'when API key is missing' do
      it 'initializes but marks service as inactive' do
        with_modified_env(JINA_API_KEY: nil) do
          service = described_class.new
          expect(service.active?).to be false
        end
      end
    end
  end

  describe '#active?' do
    context 'when API key is present' do
      it 'returns true' do
        with_modified_env(JINA_API_KEY: api_key) do
          expect(described_class.new.active?).to be true
        end
      end
    end

    context 'when API key is blank' do
      it 'returns false' do
        with_modified_env(JINA_API_KEY: '') do
          expect(described_class.new.active?).to be false
        end
      end
    end
  end

  describe '#read_url' do
    let(:jina_reader_url) { "https://r.jina.ai/#{url}" }
    let(:response_body) do
      {
        'content' => '# API Docs\n\nThis is the documentation content.'
      }.to_json
    end

    context 'when API key is not configured' do
      it 'raises ConfigurationError' do
        with_modified_env(JINA_API_KEY: nil) do
          service = described_class.new
          expect { service.read_url(url) }.to raise_error(
            Captain::Tools::JinaReaderService::ConfigurationError,
            'JINA_API_KEY not configured'
          )
        end
      end
    end

    context 'when API key is configured' do
      let(:service) { described_class.new }

      before do
        allow(ENV).to receive(:fetch).with('JINA_API_KEY', nil).and_return(api_key)
      end

      context 'when the API call is successful' do
        before do
          stub_request(:get, jina_reader_url)
            .with(headers: { 'Authorization' => "Bearer #{api_key}", 'Accept' => 'application/json' })
            .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns the content string' do
          result = service.read_url(url)
          expect(result).to be_a(String)
          expect(result).to include('API Docs')
        end
      end

      context 'when the API returns an error' do
        before do
          stub_request(:get, jina_reader_url)
            .to_return(status: 500, body: '{"error": "Internal error"}')
        end

        it 'raises RequestError' do
          expect { service.read_url(url) }.to raise_error(Captain::Tools::JinaReaderService::RequestError)
        end
      end

      context 'when the API times out' do
        before do
          stub_request(:get, jina_reader_url).to_timeout
        end

        it 'raises RequestError with timeout message' do
          expect { service.read_url(url) }.to raise_error(
            Captain::Tools::JinaReaderService::RequestError,
            /Failed to read URL/
          )
        end
      end

      context 'when URL is blank' do
        it 'raises ArgumentError' do
          expect { service.read_url('') }.to raise_error(ArgumentError, 'URL is required')
        end
      end

      context 'when URL is invalid' do
        it 'raises ArgumentError' do
          expect { service.read_url('not-a-url') }.to raise_error(ArgumentError, 'Invalid URL format')
        end
      end
    end
  end

  describe '#search' do
    let(:jina_search_url) { 'https://s.jina.ai' }
    let(:search_response) do
      {
        'data' => [
          { 'title' => 'API Docs', 'url' => 'https://example.com', 'description' => 'Documentation', 'content' => 'Content' }
        ]
      }.to_json
    end

    context 'when API key is not configured' do
      it 'raises ConfigurationError' do
        with_modified_env(JINA_API_KEY: nil) do
          service = described_class.new
          expect { service.search(query) }.to raise_error(
            Captain::Tools::JinaReaderService::ConfigurationError,
            'JINA_API_KEY not configured'
          )
        end
      end
    end

    context 'when API key is configured' do
      let(:service) { described_class.new }

      before do
        allow(ENV).to receive(:fetch).with('JINA_API_KEY', nil).and_return(api_key)
      end

      context 'when search is successful' do
        before do
          stub_request(:post, jina_search_url)
            .with(
              body: hash_including('q' => query),
              headers: { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200, body: search_response, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns array of results with symbol keys' do
          result = service.search(query)
          expect(result).to be_an(Array)
          expect(result.first[:title]).to eq('API Docs')
          expect(result.first[:url]).to eq('https://example.com')
        end
      end

      context 'when query is blank' do
        it 'raises ArgumentError' do
          expect { service.search('') }.to raise_error(ArgumentError, 'Search query is required')
        end
      end

      context 'when API fails' do
        before do
          stub_request(:post, jina_search_url).to_return(status: 500, body: '{"error": "Server error"}')
        end

        it 'raises RequestError' do
          expect { service.search(query) }.to raise_error(Captain::Tools::JinaReaderService::RequestError)
        end
      end
    end
  end
end
