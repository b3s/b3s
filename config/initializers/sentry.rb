# frozen_string_literal: true

if Rails.application.credentials.sentry_dsn.present? && !Rails.env.test?
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.sentry_dsn
    config.send_default_pii = true
    config.enabled_environments = %w[staging production]
    config.excluded_exceptions += [
      "ActionDispatch::RemoteIp::IpSpoofAttackError",
      "DynamicImage::Errors::ParameterMissing",
      "DynamicImage::Errors::InvalidSignature",
      "Mime::Type::InvalidMimeType"
    ]

    # config.traces_sample_rate = 1.0
    # config.traces_sampler = lambda do |context|
    #   transaction = context[:transaction_context]
    #
    #   # rails.request or rack.request
    #   if transaction[:op].match?(/request/) &&
    #      transaction[:name].match?(/healthcheck/)
    #     false
    #   else
    #     1.0
    #   end
    # end
  end
end
