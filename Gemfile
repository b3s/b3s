# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 4.0.0"

gem "rails", "~> 8.1.0"

gem "acts_as_list"
gem "alba"
gem "bcrypt", "~> 3.1.12"
gem "bootsnap", ">= 1.1.0", require: false
gem "dynamic_image"
gem "fastimage"
gem "fog-aws"
gem "kamal", require: false
gem "nokogiri"
gem "pg"
gem "pg_search"
gem "postmark-rails"
gem "progress_bar"
gem "puma"
gem "redcarpet", "~> 3.5"
gem "rouge"
gem "ruby-oembed", require: "oembed"
gem "thruster", require: false
gem "typhoeus"
gem "validate_url"

gem "mission_control-jobs"
gem "solid_queue"

# Frontend
gem "b3s_emoticons",
    git: "https://github.com/b3s/b3s_emoticons.git",
    branch: :main
gem "cssbundling-rails"
gem "gemoji"
gem "jsbundling-rails"
gem "propshaft", "~> 1.2.1"
gem "react-rails"

# 3rd party monitoring
gem "sentry-rails"
gem "sentry-ruby"

# Pin connection_pool to 2.x until react-rails releases a version
# compatible with connection_pool 3.x
gem "connection_pool", "~> 2.4"

group :development do
  gem "web-console"
end

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  gem "capybara"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "selenium-webdriver"
  gem "shoulda-matchers", [">= 4.3.0", "!= 4.4.0"]
  gem "simplecov"
  gem "timecop"
  gem "webmock", require: false

  gem "rubocop", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
end
