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
       SanitizeFilter,
       EmbedFilter].flatten
    end

    def render(post, options = {})
      options[:format] ||= "markdown"
      fetch_budget = options[:fetch_budget] || FetchBudget.new
      filters(options[:format]).inject(post) do |str, filter|
        filter.new(str, fetch_budget:, strict: options.fetch(:strict, false)).to_html
      end.html_safe
    end
  end
end
