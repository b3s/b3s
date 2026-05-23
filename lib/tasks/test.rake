# frozen_string_literal: true

namespace :test do
  desc "Prepare the test environment (build assets, prepare database)"
  task prepare: ["javascript:build", "css:build", "db:test:prepare"]
end
