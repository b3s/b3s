# frozen_string_literal: true

class EmbedFilter < Filter
  include ActionView::Helpers::TagHelper

  class FetchFailed < StandardError; end

  OEMBED = "div.embed[data-oembed-url]"
  YOUTUBE = "div.youtube-embed[data-youtube-id]"
  YOUTUBE_ID = /\A[\w-]{1,64}\z/

  def process(post)
    fragment = Nokogiri::HTML5::DocumentFragment.parse(post)
    placeholders(fragment).each do |element|
      element.matches?(OEMBED) ? expand_oembed(element) : expand_youtube(element)
    end
    fragment.to_html
  end

  private

  def placeholders(fragment)
    selector = "#{OEMBED}, #{YOUTUBE}"
    fragment.css(selector).reject { |element| element.ancestors(selector).any? }
  end

  def expand_oembed(element)
    url = element["data-oembed-url"]
    html = EmbedSanitizer.clean(provider_html(url), url)
    if html.present?
      element.inner_html = html
    else
      element.replace(tag.a(url, href: url, rel: SanitizeTransformers::EXTERNAL_LINK_REL))
    end
  end

  def provider_html(url)
    provider = OEmbed::Providers.find(url)
    return unless provider

    result = catch(:skip_fetch) do
      OembedResponse.html_for(url, refetch_temporary: strict?) do
        throw :skip_fetch, :temporary unless fetch_budget.spend?

        OembedFetch.call(provider, url)
      end
    end
    raise FetchFailed, url if strict? && result == :temporary

    result if result.is_a?(String)
  end

  def expand_youtube(element)
    id = element["data-youtube-id"]
    return element.remove unless id.match?(YOUTUBE_ID)

    element.replace(
      tag.iframe(title: element["data-youtube-title"],
                 src: "https://www.youtube.com/embed/#{id}",
                 frameborder: "0",
                 allowfullscreen: true,
                 sandbox: EmbedSanitizer::IFRAME_SANDBOX)
    )
  end
end
