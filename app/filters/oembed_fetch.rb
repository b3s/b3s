# frozen_string_literal: true

class OembedFetch
  include Deadlines

  DEADLINE = 5
  MAX_RESPONSE_BYTES = 262_144
  GONE_STATUSES = [400, 401, 404, 410, 501].freeze

  def self.call(provider, url)
    new(provider, url).call
  end

  def initialize(provider, url)
    @provider = provider
    @url = url
  end

  def call
    endpoint = @provider.build(@url)
    body = fetch(endpoint)
    return body if body.is_a?(Symbol)

    parse(body, endpoint.format)
  rescue StandardError => e
    Rails.logger.error "Unexpected connection error #{e.inspect}"
    gone_error?(e) ? :gone : :temporary
  end

  private

  def parse(body, format)
    OEmbed::Response.create_for(body, @provider, @url, format).html.to_s.strip
  rescue StandardError => e
    Rails.logger.info "Unusable oEmbed response for #{@url}: #{e.inspect}"
    :gone
  end

  def gone_error?(error)
    return false if error.is_a?(SsrfFilter::UnresolvedHostname)

    [SsrfFilter::Error, OEmbed::Error, URI::Error].any? { |type| error.is_a?(type) }
  end

  def fetch(endpoint)
    deadline = monotonic_now + DEADLINE
    Timeout.timeout(DEADLINE + 2) { request(endpoint, deadline) }
  end

  def request(endpoint, deadline)
    result = catch(:oembed_fetch) do
      SsrfFilter.get(endpoint, request_options(deadline)) do |response|
        next if response.is_a?(Net::HTTPRedirection)

        throw :oembed_fetch, response_result(response, deadline)
      end
    end
    result.is_a?(String) || result.is_a?(Symbol) ? result : :temporary
  end

  def response_result(response, deadline)
    return read(response, deadline) if response.is_a?(Net::HTTPSuccess)

    GONE_STATUSES.include?(response.code.to_i) ? :gone : :temporary
  end

  def request_options(deadline)
    { max_redirects: 3,
      resolver: deadline_resolver(deadline, :oembed_fetch),
      headers: { "User-Agent" => "Mozilla/5.0 (compatible; ruby-oembed/#{OEmbed::VERSION})",
                 "Accept-Encoding" => "identity" },
      http_options: { open_timeout: 2, read_timeout: 2 },
      request_proc: ->(_) { throw :oembed_fetch if monotonic_now >= deadline } }
  end

  def read(response, deadline)
    data = +""
    response.read_body do |chunk|
      data << chunk
      throw :oembed_fetch, :gone if data.bytesize > MAX_RESPONSE_BYTES
      throw :oembed_fetch if monotonic_now >= deadline
    end
    data
  end
end
