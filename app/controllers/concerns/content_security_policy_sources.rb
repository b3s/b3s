# frozen_string_literal: true

module ContentSecurityPolicySources
  extend ActiveSupport::Concern

  STYLESHEET_ORIGIN_PATTERN = %r{
    \A(https://(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+
    [a-z](?:[a-z0-9-]*[a-z0-9])?)(?:[/?#]|\z)
  }ix

  included do
    content_security_policy do |policy|
      if (origin = user_stylesheet_origin)
        policy.style_src(*policy.directives["style-src"], origin)
        policy.font_src(*policy.directives["font-src"], origin)
      end
    end
  end

  private

  def user_stylesheet_origin
    url = current_user&.custom_stylesheet_url(mobile: request.variant.mobile?)
    url.to_s[STYLESHEET_ORIGIN_PATTERN, 1]&.downcase
  end
end
