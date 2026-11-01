# frozen_string_literal: true

if Rails.application.credentials.sentry_dsn.present? && !Rails.env.test?
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.sentry_dsn
    config.data_collection.user_info = true
    config.data_collection.http_headers.request.terms =
      Sentry::DataCollection::PII_HEADER_SNIPPETS
    config.data_collection.url_query_params = true
    config.data_collection.queues = true
    config.enabled_environments = %w[staging production]

    config.rails.structured_logging.enabled = false
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
