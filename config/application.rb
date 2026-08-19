# frozen_string_literal: true

require_relative "boot"

require File.expand_path("../app/themes/theme", __dir__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module B3s
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.active_record.schema_format = :sql

    config.solid_queue.connects_to = { database: { writing: :queue } }

    config.semantic_logger.application = "b3s"

    $stdout.sync = true unless Rails.env.test?

    config.rails_semantic_logger.appenders do |appenders|
      appenders.add(file_name: config.paths["log"].first, formatter: :color) if Rails.env.local?

      unless Rails.env.test?
        appenders.add(
          io: $stdout,
          formatter: Rails.env.local? ? :color : :json,
          filter: ->(log) { log.name != "Rails::HealthController" }
        )
      end
    end
  end
end
