# frozen_string_literal: true

class EmbedFilter < Filter
  include ActionView::Helpers::TagHelper

  OEMBED = "div.embed[data-oembed-url]"
  YOUTUBE = "div.youtube-embed[data-youtube-id]"
  YOUTUBE_ID = /\A[\w-]{1,64}\z/
  FETCH_DEADLINE = 5
  MAX_RESPONSE_BYTES = 262_144

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

    catch(:skip_fetch) do
      OembedResponse.html_for(url) do
        throw :skip_fetch unless fetch_budget.spend?

        fetch_html(provider, url)
      end
    end
  end

  def fetch_html(provider, url)
    endpoint = provider.build(url)
    body = fetch_endpoint(endpoint)
    OEmbed::Response.create_for(body, provider, url, endpoint.format).html.strip if body
  rescue StandardError => e
    logger.error "Unexpected connection error #{e.inspect}"
    nil
  end

  def fetch_endpoint(endpoint)
    deadline = monotonic_now + FETCH_DEADLINE
    Timeout.timeout(FETCH_DEADLINE + 2) { request_endpoint(endpoint, deadline) }
  end

  def request_endpoint(endpoint, deadline)
    body = nil
    catch(:oembed_fetch) do
      SsrfFilter.get(endpoint, endpoint_request_options(deadline)) do |response|
        next if response.is_a?(Net::HTTPRedirection)

        body = read_endpoint(response, deadline) if response.is_a?(Net::HTTPSuccess)
        throw :oembed_fetch
      end
    end
    body
  end

  def endpoint_request_options(deadline)
    { max_redirects: 3,
      resolver: deadline_resolver(deadline, :oembed_fetch),
      headers: { "User-Agent" => "Mozilla/5.0 (compatible; ruby-oembed/#{OEmbed::VERSION})",
                 "Accept-Encoding" => "identity" },
      http_options: { open_timeout: 2, read_timeout: 2 },
      request_proc: ->(_) { throw :oembed_fetch if monotonic_now >= deadline } }
  end

  def read_endpoint(response, deadline)
    data = +""
    response.read_body do |chunk|
      data << chunk
      throw :oembed_fetch if data.bytesize > MAX_RESPONSE_BYTES || monotonic_now >= deadline
    end
    data
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
