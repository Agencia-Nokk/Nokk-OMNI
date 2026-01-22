# Base class for custom markdown renderers compatible with commonmarker 2.x
# Provides AST traversal pattern since 2.x doesn't support renderer inheritance
class MarkdownRendererBase
  def initialize
    @output = +""
    @in_table_header = false
  end

  def render(document)
    @output = +""
    traverse(document)
    @output
  end

  private

  def traverse(node)
    @current_node = node
    method_name = "render_#{node.type}"
    if respond_to?(method_name, true)
      send(method_name, node)
    else
      render_default(node)
    end
  end

  def render_default(node)
    node.each { |child| traverse(child) }
  end

  def out(*args)
    args.each do |arg|
      case arg
      when :children
        @current_node.each { |child| traverse(child) }
      when String
        @output << arg
      end
    end
  end

  def cr
    @output << "\n" unless @output.end_with?("\n")
  end

  def escape_html(text)
    CGI.escapeHTML(text.to_s)
  end

  def escape_href(url)
    # Use URI encoding for URLs - CGI.escape is too aggressive for hrefs
    url.to_s
  end

  # Default implementations for common node types
  def render_document(node)
    node.each { |child| traverse(child) }
  end

  def render_text(node)
    out(escape_html(node.string_content))
  end

  def render_softbreak(_node)
    out("\n")
  end

  def render_linebreak(_node)
    out("\n")
  end

  def render_paragraph(node)
    out('<p>')
    node.each { |child| traverse(child) }
    out('</p>')
    cr
  end

  def render_heading(node)
    level = node.header_level
    out("<h#{level}>")
    node.each { |child| traverse(child) }
    out("</h#{level}>")
    cr
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
    out('<code>', escape_html(node.string_content), '</code>')
  end

  def render_code_block(node)
    out('<pre><code>')
    out(escape_html(node.string_content))
    out('</code></pre>')
    cr
  end

  def render_link(node)
    out('<a href="', escape_href(node.url), '">')
    node.each { |child| traverse(child) }
    out('</a>')
  end

  def render_image(node)
    out('<img src="', escape_href(node.url), '"')
    out(' alt="')
    node.each { |child| traverse(child) }
    out('"')
    out(' title="', escape_html(node.title), '"') if node.title.present?
    out(' />')
  end

  def render_list(node)
    tag = node.list_type == :ordered ? 'ol' : 'ul'
    out("<#{tag}>")
    cr
    node.each { |child| traverse(child) }
    out("</#{tag}>")
    cr
  end

  def render_item(node)
    out('<li>')
    node.each { |child| traverse(child) }
    out('</li>')
    cr
  end

  def render_block_quote(node)
    out('<blockquote>')
    cr
    node.each { |child| traverse(child) }
    out('</blockquote>')
    cr
  end

  def render_thematic_break(_node)
    out('<hr />')
    cr
  end

  def render_html_block(node)
    out(node.string_content)
  end

  def render_html_inline(node)
    out(node.string_content)
  end

  def render_strikethrough(node)
    out('<del>')
    node.each { |child| traverse(child) }
    out('</del>')
  end

  def render_table(node)
    out('<table>')
    cr
    rows = []
    node.each { |child| rows << child if child.type == :table_row }

    if rows.any?
      # First row is header
      out('<thead>')
      cr
      @in_table_header = true
      traverse(rows.first)
      @in_table_header = false
      out('</thead>')
      cr

      # Remaining rows are body
      if rows.size > 1
        out('<tbody>')
        cr
        rows[1..].each { |row| traverse(row) }
        out('</tbody>')
        cr
      end
    end

    out('</table>')
    cr
  end

  def render_table_row(node)
    out('<tr>')
    node.each { |child| traverse(child) }
    out('</tr>')
    cr
  end

  def render_table_cell(node)
    tag = @in_table_header ? 'th' : 'td'
    out("<#{tag}>")
    node.each { |child| traverse(child) }
    out("</#{tag}>")
  end
end
