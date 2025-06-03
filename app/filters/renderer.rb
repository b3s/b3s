# frozen_string_literal: true

class Renderer
  class << self
    def filters(format)
      [AutolinkFilter,
       format == "markdown" ? MarkdownFilter : SimpleFilter,
       CodeFilter,
       ImageFilter,
       LinkFilter,
       PostImageFilter,
       SanitizeFilter].flatten
    end

    def render(post, options = {})
      options[:format] ||= "markdown"
      filters(options[:format]).inject(post) do |str, filter|
        filter.new(str).to_html
      end
    end
  end
end
