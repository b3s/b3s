# frozen_string_literal: true

class SanitizeFilter < Filter
  LINK_SCHEMES = %w[http https mailto relative].freeze
  MEDIA_SCHEMES = %w[http https relative].freeze

  URL_ATTRIBUTES = {
    "a" => { "href" => LINK_SCHEMES },
    "audio" => { "src" => MEDIA_SCHEMES },
    "blockquote" => { "cite" => MEDIA_SCHEMES },
    "del" => { "cite" => MEDIA_SCHEMES },
    "div" => { "data-oembed-url" => %w[http https] },
    "iframe" => { "src" => %w[https] },
    "img" => { "src" => MEDIA_SCHEMES + ["data"],
               "srcset" => MEDIA_SCHEMES,
               "data-full-src" => MEDIA_SCHEMES },
    "ins" => { "cite" => MEDIA_SCHEMES },
    "q" => { "cite" => MEDIA_SCHEMES },
    "source" => { "src" => MEDIA_SCHEMES, "srcset" => MEDIA_SCHEMES },
    "video" => { "src" => MEDIA_SCHEMES, "poster" => MEDIA_SCHEMES }
  }.freeze

  PROVIDER_CLASSES = %w[bluesky-embed fb-post fb-video fb-xfbml-parse-ignore
                        imgur-embed-pub instagram-media mastodon-embed
                        tumblr-post].freeze

  CONFIG = Sanitize::Config.freeze_config(
    elements: %w[a abbr audio b bdi bdo big blockquote br caption center cite
                 code col colgroup dd del details dfn div dl dt em figcaption
                 figure font h1 h2 h3 h4 h5 h6 hr i iframe img ins kbd li mark
                 ol p picture pre q rp rt ruby s samp small source span strike
                 strong sub summary sup table tbody td tfoot th thead time tr
                 tt u ul var video wbr],
    attributes: {
      all: %w[class dir lang style title],
      "a" => %w[href target],
      "audio" => %w[controls loop preload src],
      "blockquote" => %w[cite],
      "col" => %w[span width],
      "colgroup" => %w[span width],
      "del" => %w[cite datetime],
      "details" => %w[open],
      "div" => %w[data-oembed-url data-youtube-id data-youtube-title],
      "font" => %w[color face size],
      "iframe" => %w[allow allowfullscreen frameborder height loading
                     referrerpolicy sandbox scrolling src width],
      "img" => %w[align alt border data-full-src height loading sizes src
                  srcset width],
      "ins" => %w[cite datetime],
      "li" => %w[value],
      "ol" => %w[reversed start type],
      "q" => %w[cite],
      "source" => %w[media sizes src srcset type],
      "table" => %w[border cellpadding cellspacing width],
      "td" => %w[align colspan rowspan valign width],
      "th" => %w[align colspan rowspan scope valign width],
      "time" => %w[datetime],
      "tr" => %w[align valign],
      "ul" => %w[type],
      "video" => %w[autoplay controls height loop muted playsinline poster
                    preload src width]
    },
    css: Sanitize::Config::RELAXED[:css],
    transformers: [
      SanitizeTransformers.url_attributes(URL_ATTRIBUTES),
      SanitizeTransformers.iframe_permissions,
      SanitizeTransformers.remove_classes(PROVIDER_CLASSES)
    ]
  )

  def process(post)
    Sanitize.fragment(post, CONFIG)
  end
end
