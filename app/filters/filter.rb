# frozen_string_literal: true

class Filter
  include Deadlines

  attr_accessor :post
  attr_reader :fetch_budget

  def initialize(post, fetch_budget: FetchBudget.new, strict: false)
    @post = post
    @fetch_budget = fetch_budget
    @strict = strict
  end

  def strict?
    @strict
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

    catch(:skip_probe) do
      yield.tap do |result|
        Rails.cache.write(key, { result: }, expires_in: result ? 1.week : 1.hour)
      end
    end
  end
end
