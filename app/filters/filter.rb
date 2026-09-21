# frozen_string_literal: true

class Filter
  attr_accessor :post

  def initialize(post)
    @post = post
  end

  def process(post)
    post
  end

  def to_html
    process(@post)
  end

  def logger
    @logger ||= Rails.logger
  end

  private

  def cached_probe(scope, url)
    key = "filter/#{scope}/#{Digest::SHA256.hexdigest(url)}"
    cached = Rails.cache.read(key)
    return cached[:result] if cached

    yield.tap do |result|
      Rails.cache.write(key, { result: }, expires_in: result ? 1.week : 1.hour)
    end
  end
end
