# frozen_string_literal: true

OEmbed::Providers.register_all
OEmbed::Providers.unregister(
  OEmbed::Providers::Twitter,
  OEmbed::Providers::FacebookPost,
  OEmbed::Providers::FacebookVideo,
  OEmbed::Providers::Instagram
)

MASTODON_PROVIDERS = [
  "fosstodon.org",
  "hachyderm.io",
  "indieweb.social",
  "infosec.exchange",
  "journa.host",
  "mas.to",
  "mastodon.art",
  "mastodon.cloud",
  "mastodon.ie",
  "mastodon.online",
  "mastodon.sdf.org",
  "mastodon.social",
  "mastodon.world",
  "mstdn.ca",
  "mstdn.party",
  "mstdn.social",
  "octodon.social",
  "ruby.social",
  "snabelen.no",
  "techhub.social",
  "news.twtr.plus",
  "bne.social"
].freeze

MASTODON_PROVIDERS.each do |host|
  OEmbed::Provider.new("https://#{host}/api/oembed").tap do |provider|
    provider << "http://*.#{host}/*"
    provider << "https://*.#{host}/*"
    OEmbed::Providers.register(provider)
  end
end

OEmbed::Provider.new("https://embed.bsky.app/oembed").tap do |provider|
  provider << "http://*.bsky.app/*"
  provider << "https://*.bsky.app/*"
  OEmbed::Providers.register(provider)
end

OEmbed::Provider.new("https://oembed.tidal.com/").tap do |provider|
  provider << "http://*.tidal.com/*"
  provider << "https://*.tidal.com/*"
  OEmbed::Providers.register(provider)
end

OEmbed::Provider.new(
  "https://graph.facebook.com/v26.0/oembed_post", format: :json
).tap do |provider|
  provider << "https://www.facebook.com/*/posts/*"
  provider << "https://www.facebook.com/*/activity/*"
  provider << "https://www.facebook.com/photo*"
  provider << "https://www.facebook.com/*/photo*"
  provider << "https://www.facebook.com/media*"
  provider << "https://www.facebook.com/questions*"
  provider << "https://www.facebook.com/notes*"
  OEmbed::Providers.register(provider)
end

OEmbed::Provider.new(
  "https://graph.facebook.com/v26.0/oembed_video", format: :json
).tap do |provider|
  provider << "https://www.facebook.com/*/videos/*"
  provider << "https://www.facebook.com/video*"
  OEmbed::Providers.register(provider)
end

OEmbed::Provider.new(
  "https://graph.facebook.com/v26.0/instagram_oembed", format: :json
).tap do |provider|
  provider << "http://instagr.am/p/*"
  provider << "http://instagram.com/p/*"
  provider << "http://www.instagram.com/p/*"
  provider << "https://instagr.am/p/*"
  provider << "https://instagram.com/p/*"
  provider << "https://www.instagram.com/p/*"
  provider << "http://instagr.am/tv/*"
  provider << "http://instagram.com/tv/*"
  provider << "http://www.instagram.com/tv/*"
  provider << "https://instagr.am/tv/*"
  provider << "https://instagram.com/tv/*"
  provider << "https://www.instagram.com/tv/*"
  provider << "http://instagram.com/reel/*"
  provider << "http://www.instagram.com/reel/*"
  provider << "https://instagram.com/reel/*"
  provider << "https://www.instagram.com/reel/*"
  OEmbed::Providers.register(provider)
end
