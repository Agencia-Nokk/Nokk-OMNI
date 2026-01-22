class Messages::MarkdownRenderers::BaseMarkdownRenderer < MarkdownRendererBase
  def render_document(node)
    node.each { |child| traverse(child) }
  end

  def render_paragraph(node)
    node.each { |child| traverse(child) }
    cr
  end

  def render_text(node)
    out(node.string_content)
  end

  def render_softbreak(_node)
    out(' ')
  end

  def render_linebreak(_node)
    out("\n")
  end

  def render_strikethrough(node)
    out('<del>')
    node.each { |child| traverse(child) }
    out('</del>')
  end

  # Handle unknown node types by rendering children and adding newline
  def render_default(node)
    node.each { |child| traverse(child) }
    cr unless %i[text softbreak linebreak].include?(node.type)
  end
end
