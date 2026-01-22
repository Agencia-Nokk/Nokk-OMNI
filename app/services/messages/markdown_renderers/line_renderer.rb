class Messages::MarkdownRenderers::LineRenderer < Messages::MarkdownRenderers::BaseMarkdownRenderer
  def render_strong(node)
    out(' *')
    node.each { |child| traverse(child) }
    out('* ')
  end

  def render_emph(node)
    out(' _')
    node.each { |child| traverse(child) }
    out('_ ')
  end

  def render_code(node)
    out(' `', node.string_content, '` ')
  end

  def render_link(node)
    out(node.url)
  end

  def render_list(node)
    node.each { |child| traverse(child) }
    cr
  end

  def render_item(node)
    node.each { |child| traverse(child) }
    cr
  end

  def render_code_block(node)
    out(' ```', "\n", node.string_content, '``` ', "\n")
  end

  def render_block_quote(node)
    node.each { |child| traverse(child) }
    cr
  end
end
