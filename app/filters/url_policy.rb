# frozen_string_literal: true

module UrlPolicy
  DATA_IMAGE_TYPES = %w[image/avif image/gif image/jpeg image/png image/webp].freeze

  DATA_IMAGE_MAX_BYTES = 100_000

  class << self
    def clean_attribute(name, value, schemes)
      return clean_srcset(value, schemes) if name == "srcset"

      clean_url(value, schemes)
    end

    def scheme(url)
      if (match = url.match(/\A([a-z][a-z\d+\-.]*):/i))
        match[1].downcase
      elsif url.start_with?("//")
        "scheme-relative"
      elsif !url.match?(%r{\A[^/?#]*:})
        "relative"
      end
    end

    private

    def clean_srcset(value, schemes)
      candidates = value.split(",").map(&:strip).compact_blank.map do |candidate|
        url, descriptor = candidate.split(/\s+/, 2)
        clean_url(url, schemes)&.then { |clean| [clean, descriptor].compact.join(" ") }
      end
      candidates.join(", ") if candidates.any? && candidates.all?
    end

    def clean_url(value, schemes)
      url = normalize(value)
      case (url_scheme = scheme(url))
      when nil then nil
      when "scheme-relative" then clean_scheme_relative_url(url, schemes)
      when "data" then url if schemes.include?("data") && data_image?(url)
      else url if schemes.include?(url_scheme)
      end
    end

    def normalize(value)
      value.to_s.gsub(/[\t\n\r]/, "").gsub(/\A[\u0000- ]+|[\u0000- ]+\z/, "")
    end

    def clean_scheme_relative_url(url, schemes)
      if schemes.include?("relative")
        url
      elsif schemes.include?("https")
        "https:#{url}"
      end
    end

    def data_image?(url)
      url.bytesize <= DATA_IMAGE_MAX_BYTES &&
        DATA_IMAGE_TYPES.include?(url.sub(/\Adata:/i, "").split(/[;,]/, 2).first.to_s.strip.downcase)
    end
  end
end
