# frozen_string_literal: true

module ContentSecurityPolicySources
  extend ActiveSupport::Concern

  STYLESHEET_ORIGIN_PATTERN = %r{
    \A(https://(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+
    [a-z](?:[a-z0-9-]*[a-z0-9])?)(?:[/?#]|\z)
  }ix

  included do
    content_security_policy do |policy|
      if (origin = cable_origin)
        policy.connect_src(*policy.directives["connect-src"], origin)
      end

      if (origin = user_stylesheet_origin)
        policy.style_src(*policy.directives["style-src"], origin)
        policy.font_src(*policy.directives["font-src"], origin)
      end
    end
  end

  private

  def cable_origin
    host = request.host_with_port
    return unless host.match?(/\A[a-z0-9.-]+(:\d+)?\z/i)

    "#{request.ssl? ? 'wss' : 'ws'}://#{host}"
  end

  def user_stylesheet_url
    return unless current_user?

    if request.variant.mobile?
      current_user.mobile_stylesheet_url
    else
      current_user.stylesheet_url
    end
  end

  def user_stylesheet_origin
    user_stylesheet_url.to_s.strip[STYLESHEET_ORIGIN_PATTERN, 1]&.downcase
  end
end
