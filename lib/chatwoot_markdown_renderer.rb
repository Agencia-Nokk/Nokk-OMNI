class ChatwootMarkdownRenderer
  def initialize(content)
    @content = content
  end

  def render_message
    markdown_renderer = BaseMarkdownRenderer.new
    doc = Commonmarker.parse(@content, options: { extension: { strikethrough: true } })
    html = markdown_renderer.render(doc)
    render_as_html_safe(html)
  end

  def render_article
    markdown_renderer = CustomMarkdownRenderer.new
    doc = Commonmarker.parse(@content, options: { extension: { table: true } })
    html = markdown_renderer.render(doc)

    render_as_html_safe(html)
  end

  def render_markdown_to_plain_text
    doc = Commonmarker.parse(@content)
    extract_plain_text(doc)
  end

  private

  def render_as_html_safe(html)
    # rubocop:disable Rails/OutputSafety
    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def extract_plain_text(node, result = +"")
    case node.type
    when :text, :code
      result << node.string_content
    when :softbreak, :linebreak
      result << "\n"
    end
    node.each { |child| extract_plain_text(child, result) }
    result.strip
  end
end
