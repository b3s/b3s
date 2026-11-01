# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Embeds", :js do
  let(:user) { create(:user) }
  let(:discussion) { create(:discussion, poster: user) }
  let(:body) { nil }

  def bluesky_embed(id)
    "<blockquote class=\"bluesky-embed\" " \
      "data-bluesky-uri=\"at://did:plc:example/app.bsky.feed.post/#{id}\">" \
      "<p>Post #{id}</p></blockquote>"
  end

  def mastodon_embed(url)
    "<blockquote class=\"mastodon-embed\" data-embed-url=\"#{url}\">" \
      "<a href=\"https://mastodon.example/@user/1\">View on Mastodon</a>" \
      "</blockquote>"
  end

  before do
    login_as(user)
    find_link("Sign out")
    create(:post, exchange: discussion, format: "html", body:) if body
    visit discussion_path(discussion)
  end

  context "when a post has several embeds from one provider" do
    let(:body) { bluesky_embed(1) + bluesky_embed(2) }

    it "loads the provider script once" do
      expect(page).to have_css(
        'head script[src="https://embed.bsky.app/static/embed.js"]',
        count: 1, visible: :all
      )
    end
  end

  context "when there are no embeds" do
    it "loads no provider scripts" do
      expect(page).to have_no_css('head script[src*="embed"]', visible: :all)
    end
  end

  context "when a post has a Mastodon embed" do
    let(:body) { mastodon_embed("https://mastodon.example/@user/1/embed") }

    it "replaces the blockquote with a sandboxed iframe" do
      expect(page).to have_css(
        "iframe.mastodon-embed" \
        '[src="https://mastodon.example/@user/1/embed"]' \
        '[sandbox="allow-scripts allow-same-origin allow-popups"]'
      )
    end
  end

  context "when a Mastodon embed has an unsafe URL" do
    let(:body) do
      mastodon_embed("http://mastodon.example/@user/1/embed") +
        mastodon_embed("https://user:pass@mastodon.example/@user/2/embed") +
        mastodon_embed("https://mastodon.example/@user/3") +
        mastodon_embed("https://mastodon.example/@user/4/embed")
    end

    it "replaces only the embed with a safe URL" do
      expect(page).to have_css("iframe.mastodon-embed", count: 1)
    end
  end
end
