# frozen_string_literal: true

module EmbedProviderAttributes
  URLS = {
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

  CHECK_URLS = lambda do |env|
    node = env[:node]
    next unless node.element?

    URLS.each do |name, check|
      next unless node.has_attribute?(name)

      uri = EmbedProviderAttributes.plain_https_uri(node[name])
      node.remove_attribute(name) unless uri && check.call(node, uri)
    end
  end

  CHECK_BLUESKY_URI = lambda do |env|
    node = env[:node]
    next unless env[:node_name] == "blockquote" && node.has_attribute?("data-bluesky-uri")
    next if node["data-bluesky-uri"].match?(%r{\Aat://[\w:.\-/]+\z})

    node.remove_attribute("data-bluesky-uri")
  end

  def self.plain_https_uri(url)
    return unless url.to_s.match?(%r{\Ahttps://[^/?#:@]+(?:[/?#]|\z)})

    URI.parse(url)
  rescue URI::InvalidURIError
    nil
  end
end
