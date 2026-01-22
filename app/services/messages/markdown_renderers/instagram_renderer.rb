class Messages::MarkdownRenderers::InstagramRenderer < Messages::MarkdownRenderers::BaseMarkdownRenderer
  def initialize
    super
    @list_item_number = 0
  end

  def render_strong(node)
    out('*')
    node.each { |child| traverse(child) }
    out('*')
  end

  def render_emph(node)
    out('_')
    node.each { |child| traverse(child) }
    out('_')
  end

  def render_code(node)
    out(node.string_content)
  end

  def render_strikethrough(node)
    out('~~')
    node.each { |child| traverse(child) }
    out('~~')
  end

  def render_link(node)
    out(node.url)
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
    out(node.string_content)
  end

  def render_softbreak(_node)
    out("\n")
  end
end
