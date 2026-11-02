# frozen_string_literal: true

module UrlPolicy
  DATA_IMAGE_TYPES = %w[image/avif image/gif image/jpeg image/png image/webp].freeze

  DATA_IMAGE_MAX_BYTES = 100_000

  class << self
    def clean_url(value, protocols)
      url = value.to_s.gsub(/[\t\n\r]/, "").gsub(/\A[\u0000- ]+|[\u0000- ]+\z/, "")
      if url.start_with?("//") && protocols.exclude?(:relative) && protocols.include?("https")
        "https:#{url}"
      elsif protocol(url) != "data" || data_image?(url)
        url
      end
    end

    def clean_srcset(value, protocols)
      candidates = value.split(",").map(&:strip).compact_blank.map do |candidate|
        url, descriptor = candidate.split(/\s+/, 2)
        url = clean_url(url, protocols)
        [url, descriptor].compact.join(" ") if url && allowed?(url, protocols)
      end
      candidates.join(", ") if candidates.any? && candidates.all?
    end

    def external?(url, protocols)
      url && (protocols.nil? || allowed?(url, protocols)) &&
        (protocol(url) || url.start_with?("//", "\\", "/\\"))
    end

    def local_or_ambiguous_host?(url, domains)
      authority = url[%r{\A[a-z][a-z0-9+.-]*:[/\\]*([^/\\?#]*)}i, 1]
      return false unless authority

      host = normalized_host(authority)
      return true unless host

      domains.map { |domain| domain.strip.downcase.delete_prefix(".") }.compact_blank.any? do |domain|
        host == domain || host.end_with?(".#{domain}")
      end
    end

    private

    def normalized_host(authority)
      host = CGI.unescape(authority.split("@").last.sub(/:\d*\z/, ""))
      return unless host.valid_encoding?

      host = host.downcase.sub(/\.+\z/, "")
      host if host.match?(/\A[a-z0-9.-]+\z/)
    end

    def allowed?(url, protocols)
      protocols.include?(protocol(url) || :relative)
    end

    def protocol(url)
      url[Sanitize::REGEX_PROTOCOL, 1]&.downcase
    end

    def data_image?(url)
      url.bytesize <= DATA_IMAGE_MAX_BYTES &&
        DATA_IMAGE_TYPES.include?(url.sub(/\Adata:/i, "").split(/[;,]/, 2).first.to_s.strip.downcase)
    end
  end
end
