# frozen_string_literal: true

class Captain::Tools::Copilot::ReadApiDocumentationService < Captain::Tools::BaseTool
  MAX_CONTENT_LENGTH = 8000

  def self.name
    'read_api_documentation'
  end

  description <<~DESC
    Read API documentation from a URL and return the content in a format
    suitable for analysis. Use this tool when you need to understand an
    external API before creating a custom tool.

    **When to use:**
    - User asks to create a tool for an external API
    - User provides a documentation URL
    - After finding URLs with search_api_documentation

    **Example:**
    url: "https://viacep.com.br/ws/"
    Returns: Markdown content with API documentation

    **Note:** Content is truncated to #{MAX_CONTENT_LENGTH} characters for processing.
  DESC

  param :url, type: :string, desc: 'URL of the API documentation to read'
  param :focus, type: :string, desc: 'Specific focus area (e.g., "authentication", "endpoints")', required: false

  def execute(url:, focus: nil)
    return 'URL is required' if url.blank?
    return jina_not_configured_message unless jina_service.active?

    content = fetch_documentation(url)
    format_documentation_response(url, content, focus)
  rescue Captain::Tools::JinaReaderService::JinaError => e
    format_error_response(url, e)
  rescue ArgumentError => e
    e.message
  end

  def active?
    true
  end

  private

  def jina_service
    @jina_service ||= Captain::Tools::JinaReaderService.new
  end

  def fetch_documentation(url)
    jina_service.read_url(url)
  end

  def format_documentation_response(url, content, focus)
    truncated_content = truncate_content(content)

    {
      'content' => build_content_message(url, truncated_content, focus)
    }
  end

  def build_content_message(url, content, focus)
    message = build_header(url)
    message += build_focus_section(focus) if focus.present?
    message += build_content_section(content)
    message += build_next_steps_section
    message
  end

  def build_header(url)
    <<~HEADER
      ## API Documentation

      **Source:** #{url}
      **Retrieved:** #{Time.current.iso8601}

    HEADER
  end

  def build_focus_section(focus)
    <<~FOCUS
      **Focus area:** #{focus}

    FOCUS
  end

  def build_content_section(content)
    <<~CONTENT
      ---

      #{content}

    CONTENT
  end

  def build_next_steps_section
    <<~NEXT
      ---

      **Next steps:**
      1. Use `analyze_api_spec` to extract endpoint information
      2. Or directly use `create_custom_tool` if you have all the information needed
    NEXT
  end

  def truncate_content(content)
    return '' if content.blank?
    return content if content.length <= MAX_CONTENT_LENGTH

    truncation_notice = "\n\n[Content truncated. Original: #{content.length} chars]"
    content[0, MAX_CONTENT_LENGTH - truncation_notice.length] + truncation_notice
  end

  def format_error_response(url, error)
    <<~ERROR
      Failed to read documentation from #{url}

      **Error:** #{error.message}

      **Suggestions:**
      - Verify the URL is correct and accessible
      - Try a different documentation page
      - Use `search_api_documentation` to find alternative sources
    ERROR
  end

  def jina_not_configured_message
    <<~MSG
      Documentation reading is not available. JINA_API_KEY is not configured.

      To enable this feature:
      1. Get a free API key from https://jina.ai/
      2. Set the JINA_API_KEY environment variable

      Alternatively, you can manually provide the API specification and use `create_custom_tool` directly.
    MSG
  end
end
