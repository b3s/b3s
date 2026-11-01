# frozen_string_literal: true

class ImageFilter < Filter
  MAX_IMAGE_BYTES = 65_536
  PROBE_DEADLINE = 3
  RENDER_BUDGET = 6
  MAX_PROBES = 25

  def process(post)
    parser = Nokogiri::HTML5::DocumentFragment.parse(post)
    parser.css("img").each do |element|
      process_image(element)
    end
    parser.to_html
  end

  private

  def src?(elem)
    elem.attributes && elem.attributes["src"].present?
  end

  def image_src(elem)
    elem.attributes["src"].to_s if src?(elem)
  end

  def data_image?(url)
    url.start_with?("data:")
  end

  def needs_dimensions?(elem)
    elem.attributes["width"].blank? ||
      elem.attributes["height"].blank?
  end

  def process_image(elem)
    url = image_src(elem)
    return unless url && needs_dimensions?(elem)

    dimensions = image_size(url)
    return unless dimensions

    width, height = dimensions
    elem.set_attribute "width", width.to_s
    elem.set_attribute "height", height.to_s
  end

  def image_size(url)
    return if data_image?(url) && url.bytesize > UrlPolicy::DATA_IMAGE_MAX_BYTES

    cached_probe("image-size", url) do
      throw :skip_probe unless data_image?(url) || probe_budget?

      fetch_image_size(url)
    end
  end

  def probe_budget?
    @render_deadline ||= monotonic_now + RENDER_BUDGET
    @probes = (@probes || 0) + 1
    @probes <= MAX_PROBES && monotonic_now < @render_deadline
  end

  def fetch_image_size(url)
    data_image?(url) ? FastImage.size(url) : image_head(url)
  rescue SsrfFilter::Error, URI::Error, Timeout::Error, SocketError,
         SystemCallError, EOFError, Net::HTTPBadResponse,
         OpenSSL::SSL::SSLError
    nil
  rescue StandardError => e
    logger.error "Unexpected connection error #{e.inspect}"
    nil
  end

  def image_head(url)
    deadline = monotonic_now + PROBE_DEADLINE
    Timeout.timeout(PROBE_DEADLINE + 2) { request_dimensions(url, deadline) }
  end

  def request_dimensions(url, deadline)
    dimensions = nil
    catch(:image_head) do
      SsrfFilter.get(url, image_request_options(deadline)) do |response|
        next if response.is_a?(Net::HTTPRedirection)

        dimensions = read_dimensions(response, deadline) if response.is_a?(Net::HTTPSuccess)
        throw :image_head
      end
    end
    dimensions
  end

  def image_request_options(deadline)
    { max_redirects: 3,
      resolver: image_resolver(deadline),
      headers: { "Range" => "bytes=0-#{MAX_IMAGE_BYTES - 1}",
                 "Accept-Encoding" => "identity" },
      http_options: { open_timeout: 2, read_timeout: 2 },
      request_proc: ->(_) { throw :image_head if monotonic_now >= deadline } }
  end

  def image_resolver(deadline)
    dns = Resolv::DNS.new.tap { it.timeouts = 1 }
    lambda do |host|
      throw :image_head if monotonic_now >= deadline
      next [IPAddr.new(host)] if Resolv::AddressRegex.match?(host)

      dns.getaddresses(host).map { IPAddr.new(it.to_s) }
    end
  end

  def read_dimensions(response, deadline)
    data = +""
    dimensions = nil
    response.read_body do |chunk|
      data << chunk
      dimensions = FastImage.size(StringIO.new(data))
      break if dimensions || data.bytesize >= MAX_IMAGE_BYTES || monotonic_now >= deadline
    end
    dimensions
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
