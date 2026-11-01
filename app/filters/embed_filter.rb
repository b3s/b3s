# frozen_string_literal: true

class EmbedFilter < Filter
  include ActionView::Helpers::TagHelper

  OEMBED = "div.embed[data-oembed-url]"
  YOUTUBE = "div.youtube-embed[data-youtube-id]"
  YOUTUBE_ID = /\A[\w-]{1,64}\z/

  def process(post)
    fragment = Nokogiri::HTML5::DocumentFragment.parse(post)
    placeholders(fragment).each do |element|
      element.matches?(OEMBED) ? expand_oembed(element) : expand_youtube(element)
    end
    fragment.to_html.html_safe
  end

  private

  def placeholders(fragment)
    selector = "#{OEMBED}, #{YOUTUBE}"
    fragment.css(selector).reject { |element| element.ancestors(selector).any? }
  end

  def expand_oembed(element)
    url = element["data-oembed-url"]
    html = EmbedSanitizer.clean(provider_html(url))
    if html.present?
      element.inner_html = html
      match_embed_url_hosts(element, url)
    else
      element.replace(tag.a(url, href: url))
    end
  end

  def match_embed_url_hosts(element, url)
    host = url_host(url)
    element.css("[data-embed-url]").each do |node|
      next if host && url_host(node["data-embed-url"]) == host

      node.remove_attribute("data-embed-url")
    end
  end

  def url_host(url)
    URI.parse(url).host
  rescue URI::InvalidURIError
    nil
  end

  def provider_html(url)
    return unless OEmbed::Providers.find(url)

    OembedResponse.html_for(url) do
      OEmbed::Providers.get(url, timeout: 5).html.strip
    end
  rescue StandardError => e
    logger.error "Unexpected connection error #{e.inspect}"
    nil
  end

  def expand_youtube(element)
    id = element["data-youtube-id"]
    return element.remove unless id.match?(YOUTUBE_ID)

    element.replace(
      tag.iframe(title: element["data-youtube-title"],
                 src: "https://www.youtube.com/embed/#{id}",
                 frameborder: "0",
                 allowfullscreen: true)
    )
  end
end
