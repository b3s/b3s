# frozen_string_literal: true

class OembedResponse < ApplicationRecord
  validates :url, :html, :fetched_at, presence: true

  class << self
    def html_for(url)
      cached = find_by(url:)
      return cached.html if cached

      yield.tap { |html| store(url, html) }
    end

    def store(url, html, fetched_at: Time.current)
      create_or_find_by(url:) do |response|
        response.html = html
        response.fetched_at = fetched_at
      end
    end

    def seed_from_posts(dry_run: false)
      seen = Set.new

      posts_with_embeds.find_in_batches(order: :desc).sum do |posts|
        embeds = uncached_embeds(posts, seen)
        transaction { embeds.each { |url, (html, fetched_at)| store(url, html, fetched_at:) } } unless dry_run
        embeds.size
      end
    end

    private

    def posts_with_embeds
      Post.where("body_html LIKE ?", "%data-oembed-url%")
          .where.not("body ILIKE ?", "%data-oembed-url%")
          .where.not("body ILIKE ?", "%class=_embed_%")
          .select(:id, :body, :body_html, :updated_at)
    end

    def uncached_embeds(posts, seen)
      embeds = posts.flat_map { |post| embeds_in(post) }
                    .uniq(&:first).to_h
                    .except(*seen)
      seen.merge(embeds.keys)
      embeds.except(*where(url: embeds.keys).pluck(:url))
    end

    def embeds_in(post)
      urls = AutolinkFilter.urls(post.body)
      Nokogiri::HTML5.fragment(post[:body_html])
                     .css("div.embed[data-oembed-url]")
                     .select { |div| urls.include?(div["data-oembed-url"]) }
                     .map { |div| [div["data-oembed-url"], [div.inner_html, post.updated_at]] }
    end
  end
end
