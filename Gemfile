# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "rails", "~> 8.0.0"

gem "acts_as_list"
gem "alba"
gem "bcrypt", "~> 3.1.12"
gem "bootsnap", ">= 1.1.0", require: false
gem "dynamic_image"
gem "fastimage"
gem "fog-aws"
gem "httparty", "~> 0.17"
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
gem "validate_url"

gem "mission_control-jobs"
gem "solid_queue"

# Frontend
gem "b3s_emoticons",
    git: "https://github.com/b3s/b3s_emoticons.git",
    branch: :master
gem "cssbundling-rails"
gem "gemoji"
gem "jsbundling-rails"
gem "react-rails"
gem "sprockets-rails"
gem "terser"

# Used to generate non-digested assets for inclusion in third-party themes.
gem "non-stupid-digest-assets"

# 3rd party monitoring
gem "sentry-rails"
gem "sentry-ruby"

group :development do
  gem "web-console"
end

group :development, :test do
  gem "pry"

  gem "capybara"
  gem "factory_bot_rails"
  gem "json_spec"
  gem "rails-controller-testing"
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
