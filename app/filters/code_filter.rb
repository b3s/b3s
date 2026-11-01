# frozen_string_literal: true

class CodeFilter < Filter
  def process(post)
    parser = Nokogiri::HTML5::DocumentFragment.parse(post)

    parser.search("code").each do |element|
      code = element.content
      syntax_highlight(element, code)
    end

    parser.to_html
  end

  protected

  def find_lexer(language, code)
    Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText
  end

  def syntax_formatter
    Rouge::Formatters::HTMLLegacy.new(
      css_class: "highlight"
    )
  end

  def syntax_highlight(element, code)
    return unless element.parent.name == "pre"

    language = element.attributes["class"].try(&:value)
    lexer = find_lexer(language, code)
    element.parent.swap(syntax_formatter.format(lexer.lex(code)))
  end
end
