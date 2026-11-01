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

  PROVIDER_URLS = {
    "data-embed-url" => lambda do |node, uri|
      node.name == "blockquote" &&
        MASTODON_PROVIDERS.include?(uri.host) &&
        uri.path.end_with?("/embed")
    end,
    "data-href" => lambda do |node, uri|
      classes = node["class"].to_s.split
      if classes.intersect?(%w[fb-post fb-video])
        uri.host.to_s.match?(/(\A|\.)facebook\.com\z/)
      elsif classes.include?("tumblr-post")
        uri.host.to_s.match?(/(\A|\.)tumblr\.(com|net)\z/)
      end
    end,
    "data-instgrm-permalink" => lambda do |_node, uri|
      uri.host.to_s.match?(/(\A|\.)instagram\.com\z/)
    end
  }.freeze

  CHECK_PROVIDER_URLS = lambda do |env|
    node = env[:node]
    next unless node.element?

    PROVIDER_URLS.each do |name, check|
      next unless node.has_attribute?(name)

      uri = EmbedSanitizer.plain_https_uri(node[name])
      node.remove_attribute(name) unless uri && check.call(node, uri)
    end
  end

  CHECK_BLUESKY_URI = lambda do |env|
    node = env[:node]
    next unless env[:node_name] == "blockquote" && node.has_attribute?("data-bluesky-uri")
    next if node["data-bluesky-uri"].match?(%r{\Aat://[\w:.\-/]+\z})

    node.remove_attribute("data-bluesky-uri")
  end

  CONFIG = Sanitize::Config.freeze_config(
    elements: %w[a b blockquote br div em i iframe img p small span strong
                 time],
    attributes: {
      all: %w[dir lang title],
      "a" => %w[href],
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
      CHECK_PROVIDER_URLS,
      CHECK_BLUESKY_URI
    ]
  )

  class << self
    def clean(html)
      Sanitize.fragment(html, CONFIG)
    end

    def plain_https_uri(url)
      return unless url.to_s.match?(%r{\Ahttps://[^/?#:@]+(?:[/?#]|\z)})

      URI.parse(url)
    rescue URI::InvalidURIError
      nil
    end
  end
end
