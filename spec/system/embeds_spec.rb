# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Embeds", :js do
  let(:user) { create(:user) }
  let(:discussion) { create(:discussion, poster: user) }
  let(:body_html) { nil }
  let(:bluesky_script) { "https://embed.bsky.app/static/embed.js" }

  def browser
    page.driver.browser
  end

  def embed(url, html)
    "<div class=\"embed\" data-oembed-url=\"#{url}\">#{html}</div>"
  end

  def bluesky_embed(id)
    embed(
      "https://bsky.app/profile/example.com/post/#{id}",
      "<blockquote class=\"bluesky-embed\" " \
      "data-bluesky-uri=\"at://did:plc:example/app.bsky.feed.post/#{id}\" " \
      "data-bluesky-cid=\"bafyexample#{id}\"><p lang=\"en\">Post #{id}</p>" \
      "&mdash; <a href=\"https://bsky.app/profile/example.com/post/#{id}\">" \
      "Example</a></blockquote>"
    )
  end

  def mastodon_embed(embed_url, oembed_url: "https://mastodon.social/@user/1")
    embed(
      oembed_url,
      "<blockquote class=\"mastodon-embed\" data-embed-url=\"#{embed_url}\">" \
      "<a href=\"#{oembed_url}\">View on Mastodon</a></blockquote>"
    )
  end

  def dispatch_postsloaded
    page.execute_script(
      'document.dispatchEvent(new CustomEvent("postsloaded", { detail: [] }))'
    )
  end

  def visit_post
    if body_html
      create(:post, exchange: discussion, body: "Embed", body_html:,
                    skip_preprocess: true)
    end
    visit discussion_path(discussion)
  end

  def fixture(name)
    JSON.parse(Rails.root.join("spec/support/requests/oembed/#{name}.json").read)
  end

  def vendor_scripts
    %w[bsky facebook instagram tumblr imgur]
      .map { |host| "head script[src*=\"#{host}\"]" }.join(", ")
  end

  def visit_rendered_posts(*bodies)
    bodies.each do |body, format|
      create(:post, exchange: discussion, body:, format: format || "markdown")
    end
    visit discussion_path(discussion)
  end

  before do
    driven_by :selenium, using: :headless_chrome,
                         options: { name: :headless_chrome_offline } do |options|
      options.add_argument(
        "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1"
      )
    end
    login_as(user)
    find_link("Sign out")
  end

  context "when a post has several embeds from one provider" do
    let(:body_html) { bluesky_embed(1) + bluesky_embed(2) }

    before { visit_post }

    it "loads the provider script once" do
      expect(page).to have_css("head script[src=\"#{bluesky_script}\"]",
                               count: 1, visible: :all)
    end
  end

  context "when there are no embeds" do
    before { visit_post }

    it "loads no provider scripts" do
      expect(page).to have_no_css('head script[src*="embed"]', visible: :all)
    end
  end

  context "when a post includes the provider's own script" do
    let(:body_html) do
      bluesky_embed(1) + "<script async src=\"#{bluesky_script}\"></script>"
    end

    context "when the provider script did not run" do
      before { visit_post }

      it "loads the provider script from the app" do
        expect(page).to have_css("head script[src=\"#{bluesky_script}\"]",
                                 count: 1, visible: :all)
      end
    end

    context "when the provider script has run" do
      let!(:stub) do
        browser.execute_cdp(
          "Page.addScriptToEvaluateOnNewDocument",
          source: "window.bluesky = { scan: () => " \
                  "document.documentElement.dataset.blueskyScanned = 'true' };"
        )
      end

      before { visit_post }

      after do
        browser.execute_cdp("Page.removeScriptToEvaluateOnNewDocument",
                            identifier: stub["identifier"])
      end

      it "asks the provider to scan instead of loading it again",
         :aggregate_failures do
        expect(page).to have_css("html[data-bluesky-scanned]", visible: :all)
        expect(page).to have_no_css("head script[src=\"#{bluesky_script}\"]",
                                    visible: :all)
      end
    end
  end

  context "when a post has a Mastodon embed" do
    let(:body_html) { mastodon_embed("https://mastodon.social/@user/1/embed") }

    before { visit_post }

    it "replaces the blockquote with a sandboxed iframe" do
      expect(page).to have_css(
        "iframe.mastodon-embed" \
        '[src="https://mastodon.social/@user/1/embed"]' \
        '[sandbox="allow-scripts allow-same-origin allow-popups"]'
      )
    end

    it "does not register the iframe again when posts load" do
      expect { dispatch_postsloaded }
        .not_to(change { find("iframe.mastodon-embed")["data-embed-id"] })
    end
  end

  context "when Mastodon embeds have unsafe URLs" do
    let(:body_html) do
      [
        mastodon_embed("http://mastodon.social/@user/1/embed"),
        mastodon_embed("https://user:pass@mastodon.social/@user/2/embed"),
        mastodon_embed("https://mastodon.social/@user/3"),
        mastodon_embed("https://mastodon.example/@user/4/embed",
                       oembed_url: "https://mastodon.example/@user/4"),
        mastodon_embed("https://mastodon.social/@user/5/embed",
                       oembed_url: "https://fosstodon.org/@user/5"),
        '<blockquote class="mastodon-embed" ' \
        'data-embed-url="https://mastodon.social/@user/6/embed"></blockquote>',
        mastodon_embed("https://mastodon.social/@user/7/embed")
      ].join
    end

    before { visit_post }

    it "replaces only the embed with a safe URL" do
      expect(all("iframe.mastodon-embed", minimum: 1).pluck(:src))
        .to eq(["https://mastodon.social/@user/7/embed"])
    end
  end

  context "when a bare Mastodon URL is rendered" do
    before do
      OembedResponse.store(fixture("mastodon")["url"], fixture("mastodon")["html"])
      visit_rendered_posts(fixture("mastodon")["url"])
    end

    it "replaces the cleaned embed with an iframe" do
      expect(page).to have_css(
        "div.embed iframe.mastodon-embed" \
        "[src=\"https://mastodon.social/@ghorwood/110149321725092169/embed\"]"
      )
    end
  end

  context "when a bare Bluesky URL is rendered" do
    before do
      OembedResponse.store(fixture("bluesky")["url"], fixture("bluesky")["html"])
      visit_rendered_posts(fixture("bluesky")["url"])
    end

    it "loads the provider script" do
      expect(page).to have_css("head script[src=\"#{bluesky_script}\"]",
                               count: 1, visible: :all)
    end
  end

  context "when a user writes provider markup by hand" do
    let(:provider_markup) do
      '<blockquote class="mastodon-embed" ' \
        'data-embed-url="https://mastodon.social/@user/1/embed">a</blockquote>' \
        '<div class="fb-post" data-href="https://www.facebook.com/user/posts/1">b</div>' \
        '<blockquote class="bluesky-embed" ' \
        'data-bluesky-uri="at://did:plc:x/app.bsky.feed.post/1">c</blockquote>' \
        '<blockquote class="instagram-media" ' \
        'data-instgrm-permalink="https://www.instagram.com/p/1/">d</blockquote>' \
        '<div class="tumblr-post" data-href="https://embed.tumblr.com/embed/post/x/1">e</div>' \
        '<blockquote class="imgur-embed-pub" data-id="a/1">f</blockquote>'
    end

    before do
      control_url = fixture("mastodon")["url"]
      OembedResponse.store(control_url, fixture("mastodon")["html"])
      visit_rendered_posts(
        [provider_markup, "html"],
        [embed("https://example.com/", provider_markup), "html"],
        [embed(control_url, provider_markup), "html"]
      )
    end

    it "builds only the server-generated embed" do
      expect(all("iframe", minimum: 1).pluck(:src))
        .to eq(["https://mastodon.social/@ghorwood/110149321725092169/embed"])
    end

    it "injects no provider scripts", :aggregate_failures do
      expect(page).to have_css("iframe.mastodon-embed", count: 1)
      expect(page).to have_no_css(vendor_scripts, visible: :all)
    end
  end
end
