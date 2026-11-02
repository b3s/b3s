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
    def urls
      lambda do |env|
        node = env[:node]
        next unless node.element?

        env[:config][:protocols].fetch(env[:node_name], {}).each do |name, protocols|
          next unless node.has_attribute?(name)

          value = UrlPolicy.clean_url(node[name], protocols)
          value ? node[name] = value : node.remove_attribute(name)
        end
      end
    end

    def srcset(protocols)
      lambda do |env|
        node = env[:node]
        next unless node.element? && node.has_attribute?("srcset")

        value = UrlPolicy.clean_srcset(node["srcset"], protocols)
        value ? node["srcset"] = value : node.remove_attribute("srcset")
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

    def remove_local_iframes
      lambda do |env|
        node = env[:node]
        next unless env[:node_name] == "iframe" && node.has_attribute?("src")

        domains = B3S.config.domain_names.to_s.split(",") + Rails.application.config.hosts.grep(String)
        node.unlink if UrlPolicy.local_or_ambiguous_host?(node["src"], domains)
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

        if UrlPolicy.external?(node["href"], env[:config][:protocols].dig("a", "href"))
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
