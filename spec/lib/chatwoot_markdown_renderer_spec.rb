require 'rails_helper'

RSpec.describe ChatwootMarkdownRenderer do
  describe '#render_article' do
    let(:markdown_content) { 'This is a *test* content with ^markdown^' }
    let(:renderer) { described_class.new(markdown_content) }
    let(:rendered_content) { renderer.render_article }

    it 'renders the markdown content to html' do
      expect(rendered_content.to_s).to include('<em>test</em>')
    end

    it 'returns an html safe string' do
      expect(rendered_content).to be_html_safe
    end

    context 'when tables in markdown' do
      let(:markdown_content) do
        <<~MARKDOWN
          This is a **bold** text and *italic* text.

          | Header1      | Header2      |
          | ------------ | ------------ |
          | **Bold Cell**| *Italic Cell*|
          | Cell3        | Cell4        |
        MARKDOWN
      end

      it 'renders tables in html' do
        expect(rendered_content.to_s).to include('<table>')
        expect(rendered_content.to_s).to include('<strong>bold</strong>')
        expect(rendered_content.to_s).to include('<em>italic</em>')
      end
    end
  end

  describe '#render_message' do
    let(:markdown_content) { 'This is a **bold** and *italic* message' }
    let(:renderer) { described_class.new(markdown_content) }
    let(:rendered_message) { renderer.render_message }

    it 'renders the markdown message to html' do
      expect(rendered_message.to_s).to include('<strong>bold</strong>')
      expect(rendered_message.to_s).to include('<em>italic</em>')
    end

    it 'returns an html safe string' do
      expect(rendered_message).to be_html_safe
    end

    context 'when strikethrough in markdown' do
      let(:markdown_content) { 'This is ~~strikethrough~~ text' }

      it 'renders strikethrough' do
        expect(rendered_message.to_s).to include('<del>strikethrough</del>')
      end
    end
  end

  describe '#render_markdown_to_plain_text' do
    let(:markdown_content) { 'This is a **bold** and *italic* message with [link](https://example.com)' }
    let(:renderer) { described_class.new(markdown_content) }
    let(:rendered_content) { renderer.render_markdown_to_plain_text }

    it 'renders the markdown content to plain text' do
      expect(rendered_content).to include('bold')
      expect(rendered_content).to include('italic')
      expect(rendered_content).to include('link')
      expect(rendered_content).not_to include('**')
      expect(rendered_content).not_to include('*')
      expect(rendered_content).not_to include('[')
    end
  end
end
