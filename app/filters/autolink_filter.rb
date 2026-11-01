# frozen_string_literal: true

class AutolinkFilter < Filter
  include ActionView::Helpers::TagHelper

  URL_PATTERN = %r{(^|\s)((ftp|https?)://[^\s]+/?(\s|$))}

  def self.urls(text)
    text.scan(URL_PATTERN).filter_map { |_, match| URI.extract(match).first }
  end

  def process(post)
    post.gsub(URL_PATTERN) do
      space = Regexp.last_match(1)
      match = Regexp.last_match(2)
      uri = URI.extract(Regexp.last_match(2)).try(:first)
      space + match.gsub(uri, autolink(uri))
    end
  end

  private

  def autolink(url)
    if url.match?(/.(jpg|jpeg|gif|png|gifv|webp|avif)$/i)
      "<img src=\"#{url.gsub(/\.gifv$/, '.gif')}\">"
    elsif oembeddable?(url)
      oembed(url)
    else
      link(url)
    end
  end

  def link(url)
    "<a href=\"#{url}\">#{url}</a>"
  end

  def oembeddable?(url)
    OEmbed::Providers.find(url) ? true : false
  end

  def oembed(url)
    embed = OembedResponse.html_for(url) { OEmbed::Providers.get(url).html.strip }
    "<div class=\"embed\" data-oembed-url=\"#{url}\">#{embed}</div>"
  rescue StandardError => e
    logger.error "Unexpected connection error #{e.inspect}"
    link(url)
  end
end
