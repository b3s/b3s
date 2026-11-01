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
      expect(directive("frame-ancestors")).to eq("frame-ancestors 'self'")
    end
  end

  context "when the user has a custom stylesheet" do
    let(:user) do
      create(:user, stylesheet_url: "https://styles.example.com/b3s/custom.css")
    end

    before { get discussion_path(discussion) }

    it "allows styles from its origin" do
      expect(directive("style-src"))
        .to eq("style-src 'self' 'unsafe-inline' https://styles.example.com")
    end

    it "allows fonts from its origin" do
      expect(directive("font-src"))
        .to eq("font-src 'self' https://styles.example.com")
    end
  end

  context "when the user has a custom mobile stylesheet" do
    let(:user) do
      create(:user, stylesheet_url: "https://desktop.example.com/custom.css",
                    mobile_stylesheet_url: "https://mobile.example.com/custom.css")
    end

    before do
      configure(default_mobile_theme: "b3s")
      get discussion_path(discussion),
          headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (Linux; Android 13) " \
                                          "Mobile Safari/537.36" }
    end

    it "allows styles from the mobile stylesheet's origin" do
      expect(directive("style-src"))
        .to eq("style-src 'self' 'unsafe-inline' https://mobile.example.com")
    end
  end
end
