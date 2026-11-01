# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Quoting posts", :js do
  let(:user) { create(:user, preferred_format: format) }
  let(:format) { "markdown" }
  let(:discussion) { create(:discussion) }
  let(:literal_markup) { "<img src=x onerror=alert(1)>" }
  let(:quoted_post) do
    create(:post, exchange: discussion, user: create(:user, username: "poster"),
                  skip_preprocess: true, body: "Text", body_html: "<p>Watch #{ERB::Util.h(literal_markup)} a & b</p>")
  end

  def quote_selection
    page.execute_script(<<~JS, "post-#{quoted_post.id}")
      const post = document.getElementById(arguments[0]);
      const range = document.createRange();
      range.selectNodeContents(post.querySelector(".body .content"));
      window.getSelection().removeAllRanges();
      window.getSelection().addRange(range);
      post.querySelector("a.quote_post").click();
    JS
  end

  def image_requests
    page.evaluate_script(<<~JS)
      performance.getEntriesByType("resource")
        .map((entry) => entry.name)
        .filter((name) => /\\/x$/.test(name))
    JS
  end

  def quoted_body
    find_by_id("compose-body").value
  end

  before do
    quoted_post
    login_as(user)
    find_link("Sign out")
    visit discussion_path(discussion)
    find("#post-#{quoted_post.id} a.quote_post")
  end

  context "when the selection contains literal markup" do
    before { quote_selection }

    it "quotes the markup as text", :aggregate_failures do
      expect(quoted_body)
        .to include("Watch &lt;img src=x onerror=alert(1)&gt; a &amp; b")
      expect(image_requests).to eq([])
    end

    it "posts the quoted text unchanged", :aggregate_failures do
      click_on "Post"
      expect(find(".post .body .content", text: "Posted by poster:"))
        .to have_text("Watch #{literal_markup} a & b")
      expect(page).to have_no_css(".post .body .content img")
    end
  end

  context "when the selection contains literal markup in HTML format" do
    let(:format) { "html" }

    before { quote_selection }

    it "posts the quoted text unchanged", :aggregate_failures do
      expect(quoted_body).to start_with("<blockquote>")
      click_on "Post"
      expect(find(".post .body .content", text: "Posted by poster:"))
        .to have_text("Watch #{literal_markup} a & b")
      expect(page).to have_no_css(".post .body .content img")
    end
  end

  context "when the poster has an awkward username" do
    let(:quoted_post) do
      create(:post, exchange: discussion, user: create(:user, username: awkward_username), body: "Text")
    end

    def awkward_username
      "a<cite>\"&[b]\\"
    end

    def expect_literal_username_in_quote
      blockquote = find(".post .body .content blockquote", text: "Text")
      expect(blockquote).to have_css("cite", exact_text: "Posted by #{awkward_username}:")
      expect(blockquote).to have_link(awkward_username, exact_text: true, href: "/posts/#{quoted_post.id}")
    end

    before { find("#post-#{quoted_post.id} a.quote_post").click }

    it "escapes the username in the quote header" do
      expect(quoted_body).to include(
        "<cite>Posted by [a&lt;cite&gt;&quot;&amp;\\[b\\]&#92;](/posts/#{quoted_post.id}):</cite>"
      )
    end

    it "posts the username as literal text" do
      click_on "Post"
      expect_literal_username_in_quote
    end

    context "with HTML format" do
      let(:format) { "html" }

      it "escapes the username in the quote header" do
        expect(quoted_body).to include(
          "<cite>Posted by <a href=\"/posts/#{quoted_post.id}\">a&lt;cite&gt;&quot;&amp;[b]\\</a>:</cite>"
        )
      end

      it "posts the username as literal text" do
        click_on "Post"
        expect_literal_username_in_quote
      end
    end
  end

  context "when the poster has a newline in their username" do
    let(:quoted_post) do
      user = build(:user, username: "a\n> b").tap { it.save!(validate: false) }
      create(:post, exchange: discussion, user:, body: "Text")
    end

    def expect_single_line_username_in_quote
      blockquote = find(".post .body .content blockquote", text: "Text")
      expect(blockquote).to have_css("cite", exact_text: "Posted by a > b:")
      expect(blockquote).to have_link("a > b", exact_text: true, href: "/posts/#{quoted_post.id}")
    end

    before { find("#post-#{quoted_post.id} a.quote_post").click }

    it "collapses the newline in the quote header" do
      expect(quoted_body).to include("<cite>Posted by [a &gt; b](/posts/#{quoted_post.id}):</cite>")
    end

    it "posts the username on a single line" do
      click_on "Post"
      expect_single_line_username_in_quote
    end

    context "with HTML format" do
      let(:format) { "html" }

      it "collapses the newline in the quote header" do
        expect(quoted_body).to include(
          "<cite>Posted by <a href=\"/posts/#{quoted_post.id}\">a &gt; b</a>:</cite>"
        )
      end

      it "posts the username on a single line" do
        click_on "Post"
        expect_single_line_username_in_quote
      end
    end
  end

  context "when nothing is selected" do
    before { find("#post-#{quoted_post.id} a.quote_post").click }

    it "quotes the post content", :aggregate_failures do
      expect(quoted_body).to include("<cite>Posted by [poster](")
      expect(quoted_body)
        .to include("> <p>Watch &lt;img src=x onerror=alert(1)&gt; a &amp; b</p>")
    end
  end
end
