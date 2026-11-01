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

    def purge(url: nil, older_than: nil, dry_run: false)
      raise ArgumentError, "url or older_than is required" unless url || older_than

      scope = all
      scope = scope.where(url:) if url
      scope = scope.where(fetched_at: ...older_than) if older_than
      dry_run ? scope.count : scope.delete_all
    end
  end
end
