# frozen_string_literal: true

class ImageFilter < Filter
  MAX_IMAGE_BYTES = 65_536

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
    cached_probe("image-size", url) { fetch_image_size(url) }
  end

  def fetch_image_size(url)
    source = url.start_with?("data:") ? url : image_head(url)
    FastImage.size(source) if source
  rescue SsrfFilter::Error, URI::Error, Timeout::Error, SocketError,
         SystemCallError, EOFError, Net::HTTPBadResponse,
         OpenSSL::SSL::SSLError
    nil
  rescue StandardError => e
    logger.error "Unexpected connection error #{e.inspect}"
    nil
  end

  def image_head(url)
    data = +""
    catch(:image_head) do
      SsrfFilter.get(url, image_request_options) do |response|
        next if response.is_a?(Net::HTTPRedirection)

        read_capped(response, data) if response.is_a?(Net::HTTPSuccess)
        throw :image_head
      end
    end
    StringIO.new(data) if data.present?
  end

  def image_request_options
    { max_redirects: 3,
      headers: { "Range" => "bytes=0-#{MAX_IMAGE_BYTES - 1}",
                 "Accept-Encoding" => "identity" },
      http_options: { open_timeout: 2, read_timeout: 2 } }
  end

  def read_capped(response, data)
    response.read_body do |chunk|
      data << chunk
      throw :image_head if data.bytesize >= MAX_IMAGE_BYTES
    end
  end
end
