# frozen_string_literal: true

module ContentSecurityPolicySources
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      if user_stylesheet?
        policy.style_src(*policy.directives["style-src"], :https)
        policy.font_src(*policy.directives["font-src"], :https, :data)
      end
    end
  end

  private

  def user_stylesheet?
    url = current_user&.custom_stylesheet_url(mobile: request.variant.mobile?)
    url.to_s.match?(/\Ahttps:/i)
  end
end
