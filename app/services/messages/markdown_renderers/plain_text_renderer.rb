class Messages::MarkdownRenderers::PlainTextRenderer < Messages::MarkdownRenderers::BaseMarkdownRenderer
  def initialize
    super
    @list_item_number = 0
  end

  def render_link(node)
    node.each { |child| traverse(child) }
    out(' ', node.url) if node.url.present?
  end

  def render_strong(node)
    node.each { |child| traverse(child) }
  end

  def render_emph(node)
    node.each { |child| traverse(child) }
  end

  def render_code(node)
    out(node.string_content)
  end

  def render_list(node)
    @list_type = node.list_type
    @list_item_number = @list_type == :ordered ? node.list_start : 0
    node.each { |child| traverse(child) }
    cr
  end

  def render_item(node)
    if @list_type == :ordered
      out("#{@list_item_number}. ")
      node.each { |child| traverse(child) }
      @list_item_number += 1
    else
      out('- ')
      node.each { |child| traverse(child) }
    end
    cr
  end

  def render_block_quote(node)
    node.each { |child| traverse(child) }
    cr
  end

  def render_code_block(node)
    out(node.string_content, "\n")
  end

  def render_heading(node)
    node.each { |child| traverse(child) }
    cr
  end

  def render_thematic_break(_node)
    out("\n")
  end

  def render_softbreak(_node)
    out("\n")
  end
end
