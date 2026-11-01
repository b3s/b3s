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
  end
end
