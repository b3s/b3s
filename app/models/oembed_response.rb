# frozen_string_literal: true

class OembedResponse < ApplicationRecord
  validates :url, :html, :fetched_at, presence: true

  class << self
    def html_for(url)
      cached = find_by(url:)
      return cached.html if cached
      return if Rails.cache.exist?(failure_key(url))

      yield.tap do |html|
        html.present? ? store(url, html) : Rails.cache.write(failure_key(url), true, expires_in: 1.day)
      end
    end

    def store(url, html, fetched_at: Time.current)
      create_or_find_by(url:) do |response|
        response.html = html
        response.fetched_at = fetched_at
      end
    end

    def purge(url: nil, older_than_days: nil, dry_run: false)
      scope = purge_scope(url, older_than_days)
      dry_run ? scope.count : scope.delete_all
    end

    private

    def failure_key(url)
      "oembed-failure/#{Digest::SHA256.hexdigest(url)}"
    end

    def purge_scope(url, days)
      raise ArgumentError, "url or older_than_days is required" unless url || days
      raise ArgumentError, "older_than_days must be positive" if days && !days.positive?

      scope = url ? where(url:) : all
      days ? scope.where(fetched_at: ...days.days.ago) : scope
    end
  end
end
