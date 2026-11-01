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

  EXTERNAL_LINK_REL = "nofollow noopener noreferrer ugc"

  POSITIONS = %w[absolute relative static].freeze

  BIDI_CONTROLS = /[\u202A-\u202E\u2066-\u2069]/

  class << self
    def url_attributes(rules)
      lambda do |env|
        node = env[:node]
        next unless node.element?

        rules.fetch(env[:node_name], {}).each do |name, schemes|
          next unless node.has_attribute?(name)

          value = UrlPolicy.clean_attribute(name, node[name], schemes)
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

    def external_link_rel
      lambda do |env|
        node = env[:node]
        next unless env[:node_name] == "a"

        if node.has_attribute?("href") && UrlPolicy.scheme(node["href"]) != "relative"
          node["rel"] = EXTERNAL_LINK_REL
        else
          node.remove_attribute("rel")
        end
      end
    end

    def restrict_positioning
      lambda do |env|
        node = env[:node]
        next unless node.element? && node.has_attribute?("style")

        properties = Crass.parse_properties(node["style"]).reject { |property| unsafe_position?(property) }
        node["style"] = Crass::Parser.stringify(properties)
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

    private

    def allowed_permissions(value)
      value.split(";").map(&:strip).select do |directive|
        IFRAME_PERMISSIONS.include?(directive.split.first&.downcase)
      end.join("; ")
    end

    def unsafe_position?(property)
      property[:node] == :property &&
        property[:name].casecmp?("position") &&
        POSITIONS.exclude?(property[:value].to_s.strip.downcase)
    end
  end
end
