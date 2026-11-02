# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Security Policy" do
  let(:user) { create(:user) }
  let(:discussion) { create(:discussion) }

  def policy
    response.headers["Content-Security-Policy"]
  end

  def directive(name)
    policy.split(/;\s*/).find { |d| d.start_with?("#{name} ") }
  end

  def nonce
    directive("script-src")[/'nonce-([^']+)'/, 1]
  end

  before { login_as(user) }

  describe "GET a discussion" do
    before { get discussion_path(discussion) }

    it "enforces the policy" do
      expect(response.headers).not_to have_key("Content-Security-Policy-Report-Only")
    end

    it "allows scripts by nonce" do
      expect(directive("script-src")).to match(
        /\Ascript-src 'strict-dynamic' https: 'unsafe-inline' 'nonce-[^']+'\z/
      )
    end

    it "adds the nonce to every script tag" do
      scripts = response.parsed_body.css("script")
      expect(scripts.pluck("nonce").uniq).to eq([nonce])
    end

    it "generates a new nonce for each request" do
      first_nonce = nonce
      get discussion_path(discussion)
      expect(nonce).not_to eq(first_nonce)
    end

    it "restricts plugins, base URLs, forms and framing", :aggregate_failures do
      expect(directive("object-src")).to eq("object-src 'none'")
      expect(directive("base-uri")).to eq("base-uri 'self'")
      expect(directive("form-action")).to eq("form-action 'self'")
      expect(directive("frame-ancestors")).to eq("frame-ancestors 'none'")
    end

    it "denies framing in browsers without CSP" do
      expect(response.headers["X-Frame-Options"]).to eq("DENY")
    end

    it "blocks inline event handlers" do
      expect(directive("script-src-attr")).to eq("script-src-attr 'none'")
    end

    it "upgrades insecure requests" do
      expect(policy.split(/;\s*/)).to include("upgrade-insecure-requests")
    end

    it "allows workers from the same origin" do
      expect(directive("worker-src")).to eq("worker-src 'self'")
    end

    it "allows styles and fonts from the same origin only", :aggregate_failures do
      expect(directive("style-src")).to eq("style-src 'self' 'unsafe-inline'")
      expect(directive("font-src")).to eq("font-src 'self'")
    end

    it "allows connections to the same origin only" do
      expect(directive("connect-src")).to eq("connect-src 'self'")
    end

    it "does not report violations without a Sentry DSN" do
      expect(directive("report-uri")).to be_nil
    end
  end

  describe "custom stylesheet URLs that are not HTTPS" do
    def policy_with_stylesheet(url)
      user.stylesheet_url = url
      user.save!(validate: false)
      get discussion_path(discussion)
      policy.sub(/'nonce-[^']+'/, "'nonce'")
    end

    [
      "http://example.com/custom.css",
      "//example.com/custom.css",
      "data:text/css,body{color:red}",
      "javascript:alert(1)"
    ].each do |url|
      it "ignores #{url}" do
        expect(policy_with_stylesheet(url)).to eq(policy_with_stylesheet(nil))
      end

      it "still links #{url}" do
        policy_with_stylesheet(url)
        expect(response.parsed_body.css('link[rel="stylesheet"]').pluck("href"))
          .to include(url)
      end
    end
  end

  context "when the custom stylesheet URL contains policy syntax" do
    before do
      user.stylesheet_url = "https://example.com;script-src *"
      user.save!(validate: false)
      get discussion_path(discussion)
    end

    it "does not change the script policy" do
      expect(directive("script-src")).to match(
        /\Ascript-src 'strict-dynamic' https: 'unsafe-inline' 'nonce-[^']+'\z/
      )
    end
  end

  context "when the user has a custom stylesheet" do
    let(:user) do
      create(:user, stylesheet_url: "HTTPS://dl.dropbox.com/s/abc/custom.css?dl=1")
    end

    before { get discussion_path(discussion) }

    it "allows styles over HTTPS" do
      expect(directive("style-src")).to eq("style-src 'self' 'unsafe-inline' https:")
    end

    it "allows fonts over HTTPS and data URIs" do
      expect(directive("font-src")).to eq("font-src 'self' https: data:")
    end
  end

  context "when the custom stylesheet URL has surrounding whitespace" do
    let(:user) { create(:user) }

    before do
      user.stylesheet_url = "  https://styles.example.com/custom.css\n"
      user.save!(validate: false)
      get discussion_path(discussion)
    end

    it "links the stripped URL" do
      expect(response.parsed_body.css('link[rel="stylesheet"]').pluck("href"))
        .to include("https://styles.example.com/custom.css")
    end

    it "allows styles over HTTPS" do
      expect(directive("style-src")).to eq("style-src 'self' 'unsafe-inline' https:")
    end
  end

  context "when the user has a custom mobile stylesheet" do
    let(:user) do
      build(:user, stylesheet_url: "http://desktop.example.com/custom.css",
                   mobile_stylesheet_url: " https://mobile.example.com/custom.css ")
        .tap { |user| user.save!(validate: false) }
    end

    before do
      configure(default_mobile_theme: "b3s")
      get discussion_path(discussion),
          headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (Linux; Android 13) " \
                                          "Mobile Safari/537.36" }
    end

    it "links the stripped mobile stylesheet" do
      expect(response.parsed_body.css('link[rel="stylesheet"]').pluck("href"))
        .to include("https://mobile.example.com/custom.css")
    end

    it "allows styles over HTTPS for the mobile stylesheet" do
      expect(directive("style-src")).to eq("style-src 'self' 'unsafe-inline' https:")
    end
  end
end
