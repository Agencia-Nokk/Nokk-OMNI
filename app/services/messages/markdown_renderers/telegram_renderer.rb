class Messages::MarkdownRenderers::TelegramRenderer < Messages::MarkdownRenderers::BaseMarkdownRenderer
  def initialize
    super
    @list_item_number = 0
  end

  def render_strong(node)
    out('<strong>')
    node.each { |child| traverse(child) }
    out('</strong>')
  end

  def render_emph(node)
    out('<em>')
    node.each { |child| traverse(child) }
    out('</em>')
  end

  def render_code(node)
    out('<code>', node.string_content, '</code>')
  end

  def render_link(node)
    out('<a href="', node.url, '">')
    node.each { |child| traverse(child) }
    out('</a>')
  end

  def render_strikethrough(node)
    out('<del>')
    node.each { |child| traverse(child) }
    out('</del>')
  end

  def render_block_quote(node)
    out('<blockquote>')
    node.each { |child| traverse(child) }
    out('</blockquote>')
  end

  def render_code_block(node)
    out('<pre>', node.string_content, '</pre>')
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
      out('• ')
      node.each { |child| traverse(child) }
    end
    cr
  end

  def render_heading(node)
    out('<strong>')
    node.each { |child| traverse(child) }
    out('</strong>')
    cr
  end

  def render_softbreak(_node)
    out("\n")
  end
end
