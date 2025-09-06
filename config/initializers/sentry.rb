# frozen_string_literal: true

require "active_support/parameter_filter"

if Rails.application.credentials.sentry_dsn.present? && !Rails.env.test?
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.sentry_dsn
    config.enabled_environments = %w[staging production]
    config.excluded_exceptions += [
      "ActionDispatch::RemoteIp::IpSpoofAttackError",
      "DynamicImage::Errors::ParameterMissing",
      "DynamicImage::Errors::InvalidSignature",
      "Mime::Type::InvalidMimeType"
    ]

    config.send_default_pii = true
    filter = ActiveSupport::ParameterFilter.new(
      Rails.application.config.filter_parameters
    )
    config.before_send = lambda do |event, _hint|
      filter.filter(event.to_hash)
    end

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
