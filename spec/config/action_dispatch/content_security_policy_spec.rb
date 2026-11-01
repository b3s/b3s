# frozen_string_literal: true

require "rails_helper"

describe ActionDispatch::ContentSecurityPolicy do
  let(:config) { Rails.application.config }
  let(:sentry_dsn) { "https://abc123@o1.ingest.us.sentry.io/42" }
  let(:environment) { "production" }

  def report_uri
    config.content_security_policy.directives["report-uri"]
  end

  around do |example|
    policy = config.content_security_policy
    example.run
    config.instance_variable_set(:@content_security_policy, policy)
  end

  before do
    allow(Rails.application).to receive(:credentials)
      .and_return(ActiveSupport::OrderedOptions.new.merge!(sentry_dsn:))
    allow(Rails).to receive(:env)
      .and_return(ActiveSupport::EnvironmentInquirer.new(environment))
    load Rails.root.join("config/initializers/content_security_policy.rb")
  end

  it "reports violations to Sentry" do
    expect(report_uri).to eq(
      ["https://o1.ingest.us.sentry.io/api/42/security/" \
       "?sentry_key=abc123&sentry_environment=production"]
    )
  end

  context "without a Sentry DSN" do
    let(:sentry_dsn) { nil }

    it "does not report violations" do
      expect(report_uri).to be_nil
    end
  end

  context "when running locally" do
    let(:environment) { "development" }

    it "does not report violations" do
      expect(report_uri).to be_nil
    end
  end
end
