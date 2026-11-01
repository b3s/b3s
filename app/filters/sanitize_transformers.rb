# frozen_string_literal: true

module SanitizeTransformers
  IFRAME_PERMISSIONS = %w[
    accelerometer
    autoplay
    clipboard-write
    encrypted-media
    fullscreen
    gyroscope
    picture-in-picture
    web-share
  ].freeze

  DATA_IMAGE_TYPES = %w[image/avif image/gif image/jpeg image/png image/webp].freeze

  BIDI_CONTROLS = /[\u202A-\u202E\u2066-\u2069]/

  class << self
    def url_attributes(rules)
      lambda do |env|
        node = env[:node]
        next unless node.element?

        rules.fetch(env[:node_name], {}).each do |name, schemes|
          next unless node.has_attribute?(name)

          value = clean_url_attribute(name, node[name], schemes)
          value ? node[name] = value : node.remove_attribute(name)
        end
      end
    end

    def iframe_permissions
      lambda do |env|
        node = env[:node]
        next unless env[:node_name] == "iframe" && node.has_attribute?("allow")

        permissions = allowed_permissions(node["allow"])
        permissions.present? ? node["allow"] = permissions : node.remove_attribute("allow")
      end
    end

    def remove_classes(names)
      lambda do |env|
        node = env[:node]
        next unless node.element? && node.has_attribute?("class")

        classes = node["class"].split - names
        classes.any? ? node["class"] = classes.join(" ") : node.remove_attribute("class")
      end
    end

    def strip_bidi_controls
      lambda do |env|
        node = env[:node]
        if node.text?
          node.content = node.content.gsub(BIDI_CONTROLS, "")
        elsif node.element?
          node.attribute_nodes.each { |attr| attr.value = attr.value.gsub(BIDI_CONTROLS, "") }
        end
      end
    end

    def url_scheme(url)
      if (match = url.match(/\A([a-z][a-z\d+\-.]*):/i))
        match[1].downcase
      elsif url.start_with?("//")
        "scheme-relative"
      elsif !url.match?(%r{\A[^/?#]*:})
        "relative"
      end
    end

    private

    def allowed_permissions(value)
      value.split(";").map(&:strip).select do |directive|
        IFRAME_PERMISSIONS.include?(directive.split.first&.downcase)
      end.join("; ")
    end

    def clean_url_attribute(name, value, schemes)
      return clean_srcset(value, schemes) if name == "srcset"

      clean_url(value, schemes)
    end

    def clean_srcset(value, schemes)
      candidates = value.split(",").map(&:strip).compact_blank.map do |candidate|
        url, descriptor = candidate.split(/\s+/, 2)
        clean_url(url, schemes)&.then { |clean| [clean, descriptor].compact.join(" ") }
      end
      candidates.join(", ") if candidates.any? && candidates.all?
    end

    def clean_url(value, schemes)
      url = normalize_url(value)
      case (scheme = url_scheme(url))
      when nil then nil
      when "scheme-relative" then clean_scheme_relative_url(url, schemes)
      when "data" then url if schemes.include?("data") && data_image?(url)
      else url if schemes.include?(scheme)
      end
    end

    def normalize_url(value)
      value.to_s.gsub(/[\t\n\r]/, "").gsub(/\A[\u0000-\u0020]+|[\u0000-\u0020]+\z/, "")
    end

    def clean_scheme_relative_url(url, schemes)
      if schemes.include?("relative")
        url
      elsif schemes.include?("https")
        "https:#{url}"
      end
    end

    def data_image?(url)
      DATA_IMAGE_TYPES.include?(url.sub(/\Adata:/i, "").split(/[;,]/, 2).first.to_s.strip.downcase)
    end
  end
end
