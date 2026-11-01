# frozen_string_literal: true

module ContentSecurityPolicySources
  extend ActiveSupport::Concern

  STYLESHEET_ORIGIN_PATTERN = %r{
    \A(https://(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+
    [a-z](?:[a-z0-9-]*[a-z0-9])?)(?:[/?#]|\z)
  }ix

  DROPBOX_ORIGINS = %w[
    https://dl.dropbox.com https://www.dropbox.com https://dropbox.com
  ].freeze

  included do
    content_security_policy do |policy|
      if (origin = user_stylesheet_origin)
        style_origins = [origin, "https://fonts.googleapis.com"]
        font_origins = [origin, "https://fonts.gstatic.com"]
        if DROPBOX_ORIGINS.include?(origin)
          style_origins << "https://dl.dropboxusercontent.com"
          font_origins << "https://dl.dropboxusercontent.com"
        end
        policy.style_src(*policy.directives["style-src"], *style_origins)
        policy.font_src(*policy.directives["font-src"], *font_origins)
      end
    end
  end

  private

  def user_stylesheet_origin
    url = current_user&.custom_stylesheet_url(mobile: request.variant.mobile?)
    url.to_s[STYLESHEET_ORIGIN_PATTERN, 1]&.downcase
  end
end
