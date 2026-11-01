# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Security Policy", :js do
  let!(:user) { create(:user) }
  let(:discussion) { create(:discussion, poster: user) }
  let(:mobile_user_agent) do
    "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) " \
      "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 " \
      "Mobile/15E148 Safari/604.1"
  end

  def fixture(name)
    JSON.parse(Rails.root.join("spec/support/requests/oembed/#{name}.json").read)
  end

  def embed(url, html)
    "<div class=\"embed\" data-oembed-url=\"#{url}\">#{html}</div>"
  end

  def create_stored_post(body_html)
    create(:post, exchange: discussion, body: "Stored", body_html:,
                  skip_preprocess: true)
  end

  def wait_for_scripts
    page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      const settle = () => requestAnimationFrame(() => setTimeout(done, 100));
      if (document.readyState === "complete") {
        settle();
      } else {
        window.addEventListener("load", settle, { once: true });
      }
    JS
  end

  def expect_no_csp_violations
    wait_for_scripts
    expect(csp_violations).to eq([])
  end

  def violated_directives
    wait_for_scripts
    csp_violations.pluck("directive")
  end

  def use_offline_driver(mobile:)
    name = mobile ? :headless_chrome_offline_mobile : :headless_chrome_offline
    driven_by :selenium, using: :headless_chrome, options: { name: } do |options|
      options.add_argument(
        "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1"
      )
      options.add_argument("--user-agent=#{mobile_user_agent}") if mobile
    end
  end

  def sign_in(mobile:)
    visit new_session_path
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_on(mobile ? "Login" : "Sign in")
    find_link(mobile ? "Log out" : "Sign out", visible: :all)
  end

  def open_cable_connection
    page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      const url = location.origin.replace(/^http/, "ws") + "/cable";
      const socket = new WebSocket(url, ["actioncable-v1-json"]);
      socket.addEventListener("open", () => { socket.close(); done("open"); });
      socket.addEventListener("error", () => done("error"));
    JS
  end

  before do |example|
    mobile = example.metadata.fetch(:mobile, false)
    configure(default_mobile_theme: "b3s")
    use_offline_driver(mobile:)
    sign_in(mobile:)
    record_csp_violations
  end

  describe "thread view" do
    before do
      create(:post, exchange: discussion, body: "**Hello** <em>there</em>")
      visit discussion_path(discussion)
    end

    it "runs the application without violations", :aggregate_failures do
      expect(page).to have_css("#button-container button > span", count: 2)
      expect_no_csp_violations
    end

    it "allows the ActionCable connection" do
      expect([open_cable_connection, csp_violations]).to eq(["open", []])
    end
  end

  describe "posting form" do
    before { visit discussion_path(discussion) }

    it "previews a post without violations", :aggregate_failures do
      fill_in "compose-body", with: "Preview *this* please"
      click_on "Preview"
      expect(page).to have_css(".posts #container .post", text: "Preview this please")
      expect_no_csp_violations
    end
  end

  describe "new discussion form" do
    before { visit new_discussion_path }

    it "loads without violations" do
      expect_no_csp_violations
    end
  end

  describe "user profile" do
    it "shows the profile without violations" do
      visit user_profile_path(user.username)
      expect_no_csp_violations
    end

    it "shows the profile editor without violations" do
      visit edit_user_profile_path(user.username)
      expect_no_csp_violations
    end
  end

  describe "admin pages" do
    let!(:user) { create(:user, :admin) }

    it "shows the configuration without violations" do
      visit edit_admin_configuration_path
      expect_no_csp_violations
    end

    it "shows the job dashboard without violations", :aggregate_failures do
      visit "/jobs"
      expect(page).to have_css("section.section")
      expect_no_csp_violations
    end
  end

  describe "embeds" do
    let(:providers) do
      %w[bluesky flickr giphy imgur mastodon soundcloud spotify tidal tiktok
         tumblr vimeo youtube]
    end

    before do
      providers.each do |name|
        OembedResponse.store(fixture(name)["url"], fixture(name)["html"])
        create(:post, exchange: discussion, body: fixture(name)["url"])
      end
      create_stored_post(
        embed("https://www.instagram.com/p/1/",
              '<blockquote class="instagram-media" ' \
              'data-instgrm-permalink="https://www.instagram.com/p/1/">' \
              "Instagram</blockquote>") +
        embed("https://www.facebook.com/user/posts/1",
              '<div class="fb-post" ' \
              'data-href="https://www.facebook.com/user/posts/1">Facebook</div>')
      )
      visit discussion_path(discussion)
    end

    it "loads the vendor scripts without violations", :aggregate_failures do
      %w[embed.bsky.app instagram.com connect.facebook.net assets.tumblr.com
         s.imgur.com].each do |host|
        expect(page).to have_css("head script[src*=\"#{host}\"]", visible: :all)
      end
      expect_no_csp_violations
    end

    it "builds the Mastodon iframe without violations", :aggregate_failures do
      expect(page).to have_css("iframe.mastodon-embed")
      expect_no_csp_violations
    end
  end

  describe "script in stored post HTML" do
    before do
      create_stored_post(
        "<script>document.documentElement.dataset.inline = 'ran';</script>" \
        '<img src="/missing.png" ' \
        "onerror=\"document.documentElement.dataset.onerror = 'ran'\">"
      )
      visit discussion_path(discussion)
    end

    it "does not run", :aggregate_failures do
      expect(page).to have_css(".post img[src=\"/missing.png\"]")
      expect(violated_directives)
        .to contain_exactly("script-src-elem", "script-src-attr")
      expect(page).to have_no_css("html[data-inline], html[data-onerror]")
    end
  end

  describe "base element in stored post HTML" do
    before do
      create_stored_post(
        '<base href="https://elsewhere.example/">' \
        '<a id="relative-link" href="relative/path">Relative</a>'
      )
      visit discussion_path(discussion)
    end

    it "does not change link resolution", :aggregate_failures do
      href = find_by_id("relative-link")[:href]
      expect(URI(href).host).to eq(URI(current_url).host)
      expect(violated_directives).to eq(["base-uri"])
    end
  end

  context "with the mobile layout", :mobile do
    before do
      create(:post, exchange: discussion, body: "**Hello** <em>there</em>")
      visit discussion_path(discussion)
    end

    it "runs the mobile application without violations", :aggregate_failures do
      expect(page).to have_css("#navigationToggle")
      expect_no_csp_violations
    end
  end
end
