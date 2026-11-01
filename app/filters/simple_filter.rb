# frozen_string_literal: true

class SimpleFilter < Filter
  def process(post)
    markdown_code_blocks(post) do |str|
      convert_line_breaks(escape_angle_brackets(strip(str)))
    end
  end

  private

  def convert_line_breaks(str)
    str.gsub(/\r?\n/, "<br>\n")
  end

  def escape_angle_brackets(str)
    str.gsub(Regexp.new("<(?!/|#{html_tags.join('|')})"), "&lt;")
       .gsub(Regexp.new("(?<!\"|'|#{html_tags.join('|')})>"), "&gt;")
  end

  def html_tags
    %w[a abbr address area article aside audio b base bdi bdo blockquote body br
       button canvas caption cite code col colgroup data datalist dd del details
       dfn div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4
       h5 h6 head header hr html i iframe img input ins kbd keygen label legend
       li link main map mark math menu menuitem meta meter nav noscript object
       ol optgroup option output p param pre progress q rp rt ruby s samp script
       section select small source span strong style sub summary svg table tbody
       td textarea tfoot th thead time title tr track u ul var video wbr
       allowfullscreen base64serialized]
  end

  def markdown_code_blocks(str)
    decode_markdown_blocks(yield(encode_markdown_blocks(str)))
  end

  def encode_markdown_blocks(str)
    str.gsub(/```([\w\d_]*)\r?\n(.*?)```(?:$|(\r?\n)+)/m) do |code_block|
      html = MarkdownFilter.new(code_block).to_html.strip
      serialized = Base64.strict_encode64(html)
      "<base64serialized>#{serialized}</base64serialized>"
    end
  end

  def decode_markdown_blocks(str)
    parser = Nokogiri::HTML5::DocumentFragment.parse(str)
    parser.search("base64serialized").each do |element|
      element.swap Base64.strict_decode64(element.content)
    end
    parser.to_html
  end

  def strip(post)
    post.gsub(/\A[\s\n]*/, "").gsub(/[\s\n]*\Z/, "")
  end
end
