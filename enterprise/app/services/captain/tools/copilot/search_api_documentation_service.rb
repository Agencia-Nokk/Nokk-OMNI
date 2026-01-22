# frozen_string_literal: true

class Captain::Tools::Copilot::SearchApiDocumentationService < Captain::Tools::BaseTool
  DEFAULT_NUM_RESULTS = 5
  MAX_NUM_RESULTS = 10

  def self.name
    'search_api_documentation'
  end

  description <<~DESC
    Search the web for API documentation when you don't know the exact URL.
    Use this tool when the user mentions an API or service name but doesn't
    provide a documentation link.

    **When to use:**
    - User asks to create a tool for an API without providing docs URL
    - User mentions only the API/service name (e.g., "ViaCEP", "ReceitaWS")
    - You need to find official documentation before reading it

    **Tips for effective searches:**
    - Include "API documentation" in the query
    - Add the specific functionality (e.g., "CNPJ lookup", "CEP query")
    - Use the service name prominently

    **Example:**
    query: "ViaCEP API documentation CEP"
    Returns: List of relevant URLs with titles and descriptions
  DESC

  param :query, type: :string, desc: 'Search query (e.g., "ViaCEP API documentation")'
  param :num_results, type: :number, desc: 'Number of results (default: 5, max: 10)', required: false

  def execute(query:, num_results: nil)
    return 'Search query is required' if query.blank?
    return jina_not_configured_message unless jina_service.active?

    results = perform_search(query, num_results)
    format_search_results(query, results)
  rescue Captain::Tools::JinaReaderService::JinaError => e
    "Search failed: #{e.message}"
  end

  def active?
    true
  end

  private

  def jina_service
    @jina_service ||= Captain::Tools::JinaReaderService.new
  end

  def perform_search(query, num_results)
    options = build_search_options(num_results)
    jina_service.search(query, options)
  end

  def build_search_options(num_results)
    {
      num_results: sanitize_num_results(num_results),
      language: 'pt',
      country: 'br'
    }
  end

  def sanitize_num_results(num_results)
    return DEFAULT_NUM_RESULTS if num_results.blank?

    num_results.to_i.clamp(1, MAX_NUM_RESULTS)
  end

  def format_search_results(query, results)
    return no_results_message(query) if results.empty?

    {
      'content' => build_results_content(query, results)
    }
  end

  def build_results_content(query, results)
    <<~CONTENT
      Found #{results.size} result(s) for "#{query}":

      #{format_results_list(results)}

      **Recommendation:** Use `read_api_documentation` with the most relevant URL above to read the full documentation.
    CONTENT
  end

  def format_results_list(results)
    results.map.with_index(1) do |result, index|
      format_single_result(result, index)
    end.join("\n\n")
  end

  def format_single_result(result, index)
    <<~RESULT.strip
      ### #{index}. #{result[:title] || 'Untitled'}
      **URL:** #{result[:url]}
      **Description:** #{result[:description] || 'No description available'}
    RESULT
  end

  def no_results_message(query)
    <<~MSG
      No results found for "#{query}".

      Try:
      - Using different keywords
      - Including "API documentation" in your query
      - Searching for the service name with specific functionality
    MSG
  end

  def jina_not_configured_message
    <<~MSG
      Search functionality is not available. JINA_API_KEY is not configured.

      To enable API documentation search:
      1. Get a free API key from https://jina.ai/
      2. Set the JINA_API_KEY environment variable

      Alternatively, provide the documentation URL directly and use `read_api_documentation`.
    MSG
  end
end
