# frozen_string_literal: true

class ImageFilter < Filter
  def process(post)
    parser = Nokogiri::HTML::DocumentFragment.parse(post)
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
    cached_probe("image-size", url) do
      FastImage.size(url, timeout: 2.0)
    rescue StandardError => e
      logger.error "Unexpected connection error #{e.inspect}"
      nil
    end
  end
end
