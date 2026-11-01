# frozen_string_literal: true

class Filter
  attr_accessor :post
  attr_reader :fetch_budget

  def initialize(post, fetch_budget: FetchBudget.new)
    @post = post
    @fetch_budget = fetch_budget
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

  def deadline_resolver(deadline, tag)
    dns = Resolv::DNS.new.tap { it.timeouts = 1 }
    lambda do |host|
      throw tag if monotonic_now >= deadline
      next [IPAddr.new(host)] if Resolv::AddressRegex.match?(host)

      dns.getaddresses(host).map { IPAddr.new(it.to_s) }
    end
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

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
