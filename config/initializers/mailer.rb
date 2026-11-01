# frozen_string_literal: true

if Rails.env.production?
  Rails.application.config.action_mailer.delivery_method = :postmark
  Rails.application.config.action_mailer.postmark_settings = {
    api_token: Rails.application.credentials.postmark_api_token
  }
end

if Rails.env.production?
  Rails.application.config.action_mailer.default_url_options = {
    host: "b3s.me",
    protocol: "https"
  }
end
