# frozen_string_literal: true

class OembedResponse < ApplicationRecord
  validates :url, :html, :fetched_at, presence: true

  class << self
    def html_for(url, refetch_temporary: false)
      cached = find_by(url:)
      return cached.html if cached

      failure = cached_failure(url)
      return failure if failure == :gone || (failure && !refetch_temporary)

      record(url, yield)
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

    def record(url, result)
      return store(url, result).html if result.is_a?(String) && result.present?

      failure = result == :temporary ? :temporary : :gone
      Rails.cache.write(failure_key(url), failure, expires_in: 1.day)
      failure
    end

    def cached_failure(url)
      failure = Rails.cache.read(failure_key(url))
      return unless failure

      failure == :gone ? :gone : :temporary
    end

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
