# frozen_string_literal: true

class Captain::Tools::JinaReaderService
  READER_BASE_URL = 'https://r.jina.ai'
  SEARCH_BASE_URL = 'https://s.jina.ai'
  DEFAULT_TIMEOUT = 30
  MAX_CONTENT_LENGTH = 15_000
  DEFAULT_SEARCH_RESULTS = 5
  MAX_SEARCH_RESULTS = 10

  class JinaError < StandardError; end
  class ConfigurationError < JinaError; end
  class RequestError < JinaError; end

  def initialize
    @api_key = ENV.fetch('JINA_API_KEY', nil)
  end

  def active?
    @api_key.present?
  end

  def read_url(url)
    validate_configuration!
    validate_url!(url)

    response = perform_reader_request(url)
    process_reader_response(response)
  rescue HTTParty::Error, Timeout::Error => e
    raise RequestError, "Failed to read URL: #{e.message}"
  end

  def search(query, options = {})
    validate_configuration!
    validate_query!(query)

    response = perform_search_request(query, options)
    process_search_response(response)
  rescue HTTParty::Error, Timeout::Error => e
    raise RequestError, "Search failed: #{e.message}"
  end

  private

  def validate_configuration!
    raise ConfigurationError, 'JINA_API_KEY not configured' unless active?
  end

  def validate_url!(url)
    raise ArgumentError, 'URL is required' if url.blank?

    uri = URI.parse(url)
    raise ArgumentError, 'Invalid URL format' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    raise ArgumentError, 'Invalid URL format'
  end

  def validate_query!(query)
    raise ArgumentError, 'Search query is required' if query.blank?
  end

  def perform_reader_request(url)
    HTTParty.get(
      "#{READER_BASE_URL}/#{url}",
      headers: reader_headers,
      timeout: DEFAULT_TIMEOUT
    )
  end

  def perform_search_request(query, options)
    HTTParty.post(
      SEARCH_BASE_URL,
      headers: search_headers,
      body: search_body(query, options).to_json,
      timeout: DEFAULT_TIMEOUT
    )
  end

  def reader_headers
    {
      'Authorization' => "Bearer #{@api_key}",
      'Accept' => 'application/json'
    }
  end

  def search_headers
    {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def search_body(query, options)
    body = { q: query }
    body[:gl] = options[:country] if options[:country].present?
    body[:hl] = options[:language] if options[:language].present?
    body[:num] = [options[:num_results] || DEFAULT_SEARCH_RESULTS, MAX_SEARCH_RESULTS].min
    body
  end

  def process_reader_response(response)
    handle_error_response(response) unless response.success?

    content = extract_reader_content(response)
    truncate_content(content)
  end

  def process_search_response(response)
    handle_error_response(response) unless response.success?

    data = response.parsed_response['data'] || []
    format_search_results(data)
  end

  def extract_reader_content(response)
    parsed = response.parsed_response
    return parsed['content'] if parsed.is_a?(Hash) && parsed['content'].present?

    response.body
  end

  def format_search_results(data)
    data.map do |result|
      {
        title: result['title'],
        description: result['description'],
        url: result['url'],
        content: truncate_content(result['content'], 500)
      }
    end
  end

  def truncate_content(content, max_length = MAX_CONTENT_LENGTH)
    return '' if content.blank?
    return content if content.length <= max_length

    "#{content[0, max_length]}...\n\n[Content truncated. Original length: #{content.length} chars]"
  end

  def handle_error_response(response)
    error_message = extract_error_message(response)
    raise RequestError, "Jina API error (#{response.code}): #{error_message}"
  end

  def extract_error_message(response)
    parsed = response.parsed_response
    return parsed['message'] || parsed['error'] if parsed.is_a?(Hash)

    response.body.to_s.truncate(200)
  rescue StandardError
    'Unknown error'
  end
end
