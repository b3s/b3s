# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.connect_src :self
    policy.font_src :self
    policy.form_action :self
    policy.frame_ancestors :self
    policy.frame_src :https
    policy.img_src :self, :https, :http, :data, :blob
    policy.manifest_src :self
    policy.media_src :self, :https, :http, :blob
    policy.object_src :none
    policy.script_src :strict_dynamic, :https, :unsafe_inline
    policy.style_src :self, :unsafe_inline
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
