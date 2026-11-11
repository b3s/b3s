# frozen_string_literal: true

class LegacyEmbeds
  YOUTUBE = %r{\A(?:https?:)?//(?:www\.)?youtube(?:-nocookie)?\.com/(?:v|embed)/([\w-]{11})(?![\w-])}i
  VIMEO = %r{\A(?:https?:)?//(?:(?:www\.)?vimeo\.com/moogaloop\.swf\?(?:[^#]*&)?clip_id=|
             player\.vimeo\.com/video/)(\d+)}ix
  DAILYMOTION = %r{\A(?:https?:)?//(?:www\.)?dailymotion\.com/swf/(?:video/)?([a-z0-9]+)}i
  SOUNDCLOUD_PLAYER = %r{\A(?:https?:)?//(?:player|a1)\.soundcloud\.com/player\.swf\?}i
  SOUNDCLOUD = %r{\Ahttps?://(?:api\.)?soundcloud\.com/[^\s?#]+\z}i

  class << self
    def transformer
      lambda do |env|
        next unless %w[embed object].include?(env[:node_name])

        url = flash_urls(env[:node]).lazy.filter_map { |flash_url| oembed_url(flash_url) }.first
        env[:node].replace(placeholder(env[:node].document, url)) if url
      end
    end

    def oembed_url(flash_url)
      if (id = flash_url[YOUTUBE, 1])
        "https://www.youtube.com/watch?v=#{id}"
      elsif (id = flash_url[VIMEO, 1])
        "https://vimeo.com/#{id}"
      elsif (id = flash_url[DAILYMOTION, 1])
        "https://www.dailymotion.com/video/#{id}"
      elsif flash_url.match?(SOUNDCLOUD_PLAYER)
        soundcloud_url(flash_url)
      end
    end

    private

    def flash_urls(node)
      movies = node.css("param").select { |param| param["name"].to_s.casecmp?("movie") }
      [node["data"], node["src"], *movies.pluck("value"), *node.css("object").pluck("data"),
       *node.css("embed").pluck("src")]
        .compact.map(&:strip)
    end

    def soundcloud_url(flash_url)
      track = URI.decode_www_form(flash_url.split("?", 2).last).to_h["url"]
      track.sub(/\Ahttp:/i, "https:") if track&.match?(SOUNDCLOUD)
    rescue ArgumentError
      nil
    end

    def placeholder(document, url)
      document.create_element("div", class: "embed", "data-oembed-url" => url).tap do |div|
        div.add_child(document.create_element("a", url, href: url))
      end
    end
  end
end
