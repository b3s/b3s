# frozen_string_literal: true

class EmbedSanitizer
  URL_ATTRIBUTES = {
    "a" => { "href" => %w[http https] },
    "blockquote" => { "cite" => %w[https],
                      "data-embed-url" => %w[https],
                      "data-instgrm-permalink" => %w[https] },
    "div" => { "data-href" => %w[https] },
    "iframe" => { "src" => %w[https] },
    "img" => { "src" => %w[https] }
  }.freeze

  IFRAME_HOSTS = {
    "codepen.io" => %w[codepen.io],
    "giphy.com" => %w[giphy.com],
    "oembed.tidal.com" => %w[embed.tidal.com],
    "open.spotify.com" => %w[open.spotify.com],
    "soundcloud.com" => %w[w.soundcloud.com],
    "vimeo.com" => %w[player.vimeo.com],
    "www.kickstarter.com" => %w[www.kickstarter.com],
    "www.tiktok.com" => %w[www.tiktok.com],
    "www.youtube.com" => %w[www.youtube.com youtube.com www.youtube-nocookie.com]
  }.freeze

  CONFIG = Sanitize::Config.freeze_config(
    elements: %w[a b blockquote br div em i iframe img p small span strong
                 time],
    attributes: {
      all: %w[dir lang title],
      "a" => %w[href rel],
      "blockquote" => %w[cite class data-bluesky-cid data-bluesky-embed-color-mode
                         data-bluesky-uri data-context data-embed-url data-id
                         data-instgrm-captioned data-instgrm-permalink
                         data-instgrm-version],
      "div" => %w[class data-did data-href data-language data-width],
      "iframe" => %w[allow allowfullscreen class frameborder height loading
                     referrerpolicy sandbox scrolling src style width],
      "img" => %w[alt height src width],
      "span" => %w[class],
      "time" => %w[datetime]
    },
    css: Sanitize::Config::RELAXED[:css],
    transformers: [
      SanitizeTransformers.strip_bidi_controls,
      SanitizeTransformers.url_attributes(URL_ATTRIBUTES),
      SanitizeTransformers.iframe_permissions,
      SanitizeTransformers.restrict_positioning,
      SanitizeTransformers.external_link_rel,
      EmbedProviderAttributes::CHECK_URLS,
      EmbedProviderAttributes::CHECK_BLUESKY_URI
    ]
  )

  class << self
    def clean(html, url)
      config = Sanitize::Config.merge(
        CONFIG,
        transformers: CONFIG[:transformers] + [
          restrict_iframe_hosts(iframe_hosts(url)),
          restrict_embed_url_host(url_host(url))
        ]
      )
      Sanitize.fragment(html, config)
    end

    def iframe_hosts(url)
      endpoint_host = OEmbed::Providers.find(url)&.endpoint.to_s[%r{\Ahttps://([^/?#:]+)}, 1]&.downcase
      return [endpoint_host] if MASTODON_PROVIDERS.include?(endpoint_host)

      IFRAME_HOSTS.fetch(endpoint_host, [])
    end

    private

    def restrict_iframe_hosts(hosts)
      lambda do |env|
        next unless env[:node_name] == "iframe"
        uri = EmbedProviderAttributes.plain_https_uri(env[:node]["src"])
        next if uri && hosts.include?(uri.host.downcase)

        env[:node].unlink
      end
    end

    def restrict_embed_url_host(host)
      lambda do |env|
        node = env[:node]
        next unless node.element? && node.has_attribute?("data-embed-url")
        next if host && url_host(node["data-embed-url"]) == host

        node.remove_attribute("data-embed-url")
      end
    end

    def url_host(url)
      URI.parse(url.to_s).host&.downcase
    rescue URI::InvalidURIError
      nil
    end
  end
end
