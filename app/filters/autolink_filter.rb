# frozen_string_literal: true

class AutolinkFilter < Filter
  include ActionView::Helpers::TagHelper

  def process(post)
    post.gsub(%r{(^|\s)((ftp|https?)://[^\s]+/?(\s|$))}) do
      space = Regexp.last_match(1)
      match = Regexp.last_match(2)
      uri = URI.extract(match).first
      next space + match unless uri

      space + match.sub(uri) { autolink(uri) }
    end
  end

  private

  def autolink(url)
    if url.match?(/.(jpg|jpeg|gif|png|gifv|webp|avif)$/i)
      tag.img(src: url.gsub(/\.gifv$/, ".gif"))
    elsif oembeddable?(url)
      tag.div(link(url), class: "embed", data: { oembed_url: url })
    else
      link(url)
    end
  end

  def link(url)
    tag.a(url, href: url)
  end

  def oembeddable?(url)
    OEmbed::Providers.find(url) ? true : false
  end
end
