# frozen_string_literal: true

require "rails_helper"

describe PostsHelper do
  let(:user) { create(:user, username: "foo") }
  let(:profile_link) do
    '<a title="foo\'s profile" class="poster" href="/users/profile/foo">foo</a>'
  end

  let(:smile_image) do
    '<img alt="smile" class="emoji" ' \
      'src="/images/emoji/unicode/1f604.png" ' \
      'style="vertical-align:middle" ' \
      'width="16" height="16">'
  end

  def attribute_signature(html)
    Nokogiri::HTML5.fragment(html).css("*").map do |elem|
      [elem.name, elem.attributes.transform_values(&:value)]
    end
  end

  describe "#emojify" do
    subject { helper.emojify(input) }

    context "when emoji is defined" do
      let(:input) { ":smile:" }

      it { is_expected.to match(smile_image) }
    end

    context "when emoji isn't defined" do
      let(:input) { ":foobar:" }

      it { is_expected.to eq(":foobar:") }
    end

    context "when plain text contains markup" do
      let(:input) { "<b>:smile:</b>" }

      it { is_expected.to eq("&lt;b&gt;#{smile_image}&lt;/b&gt;") }
    end

    context "when an alias is inside attribute values" do
      let(:input) do
        '<p title=":smile:" data-alias=":smile:" style="x:smile:y">' \
        '<img alt=":smile:" src="/a.png"></p>'.html_safe
      end

      it { is_expected.to eq(input) }
    end

    context "when an alias is inside an href" do
      let(:input) { '<p><a href="/foo/:smile:/bar">x</a></p>'.html_safe }

      it { is_expected.to eq(input) }
    end

    context "when an alias is inside code" do
      let(:input) { "<p><code>:smile:</code></p>".html_safe }

      it { is_expected.to eq(input) }
    end

    context "when an alias is inside pre" do
      let(:input) { "<pre>:smile:</pre>".html_safe }

      it { is_expected.to eq(input) }
    end

    context "when an alias is inside link text" do
      let(:input) { '<p><a href="/foo">:smile:</a></p>'.html_safe }

      it { is_expected.to eq(input) }
    end

    context "when an alias is in text next to elements with attributes" do
      let(:input) { '<p title=":smile:">:smile: <em class="x">:smile:</em></p>'.html_safe }
      let(:expected) do
        "<p title=\":smile:\">#{smile_image} <em class=\"x\">#{smile_image}</em></p>"
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe "#format_post" do
    subject { helper.format_post(input, user) }

    context "with a plain string" do
      let(:input) { "/me :smile:" }

      it { is_expected.to eq("#{profile_link} #{smile_image}") }
    end

    context "with rendered post HTML" do
      let(:input) { "<p>/me :smile:</p>\n".html_safe }

      it { is_expected.to eq("<p>#{profile_link} #{smile_image}</p>\n") }
    end

    context "with attribute values containing /me and aliases" do
      let(:input) do
        '<p><a href="/me/:smile:" title="/me :smile:">/me :smile:</a> /me :smile:</p>'.html_safe
      end
      let(:expected) do
        '<p><a href="/me/:smile:" title="/me :smile:">/me :smile:</a> ' \
          "#{profile_link} #{smile_image}</p>"
      end

      it { is_expected.to eq(expected) }
    end

    context "with a corpus of sanitized HTML" do
      let(:corpus) do
        ['<p title="/me :smile:" data-x=":+1:">/me :smile:</p>',
         '<p><img alt=":smile:" title="/me" src="/i.png" style="a:smile:b"> :smile:</p>',
         '<p><a href="/me" title=":smile: /me">/me</a> and /me</p>',
         "<blockquote><p>/me <em>:smile:</em><br>/me :+1:</p></blockquote>",
         '<p title="a&quot; b=&quot;:smile:">/me</p>',
         "<p title=\"x>/me <b>:smile:</b>\">/me</p>",
         "<pre><code class=\"ruby\">/me :smile:</code></pre>",
         '<ul><li data-me="/me">/me</li><li>:smile:</li></ul>',
         "<p>:smile::smile: /me/me</p>"].map { |html| SanitizeFilter.new(html).to_html }
      end

      def without_inserted(html)
        attribute_signature(html).reject do |name, attributes|
          (name == "img" && attributes["class"] == "emoji") ||
            (name == "a" && attributes["class"] == "poster")
        end
      end

      it "preserves the attributes of every element" do
        corpus.each do |html|
          expect(without_inserted(helper.format_post(html, user)))
            .to eq(attribute_signature(html))
        end
      end

      it "only inserts emoji images and profile links" do
        corpus.each do |html|
          inserted = attribute_signature(helper.format_post(html, user)) -
                     attribute_signature(html)
          expect(inserted.map(&:first) - %w[img a]).to eq([])
        end
      end
    end
  end

  describe "#meify" do
    subject { helper.meify(input, user) }

    context "when string starts with /me" do
      let(:input) { "/me blushes" }

      it { is_expected.to eq("#{profile_link} blushes") }
    end

    context "when string includes /me" do
      let(:input) { "checkout /me here" }

      it { is_expected.to eq("checkout #{profile_link} here") }
    end

    context "when /me isn't separated by spaces" do
      let(:input) { "b3s.me/me" }

      it { is_expected.to eq(input) }
    end

    context "when /me follows an HTML tag in safe content" do
      let(:input) { "<p>/me blushes</p>\n".html_safe }

      it { is_expected.to eq("<p>#{profile_link} blushes</p>\n") }
    end

    context "when /me follows an HTML tag in unsafe content" do
      let(:input) { "<p>/me blushes</p>" }

      it { is_expected.to eq("&lt;p&gt;/me blushes&lt;/p&gt;") }
    end

    context "when /me follows a line break" do
      let(:input) { "<p>foo<br>/me blushes</p>".html_safe }

      it { is_expected.to eq("<p>foo<br>#{profile_link} blushes</p>") }
    end

    context "when /me follows a closing tag" do
      let(:input) { "<p><em>foo</em>/me blushes</p>".html_safe }

      it { is_expected.to eq(input) }
    end

    context "when /me is inside attribute values" do
      let(:input) do
        '<p title="/me" data-me=" /me" style="x /me"><img alt="/me" src="/me"></p>'.html_safe
      end

      it { is_expected.to eq(input) }
    end

    context "when /me is inside code" do
      let(:input) { "<p><code>/me blushes</code></p>".html_safe }

      it { is_expected.to eq(input) }
    end

    context "when /me is inside link text" do
      let(:input) { '<p><a href="/foo">/me</a></p>'.html_safe }

      it { is_expected.to eq(input) }
    end
  end

  describe "#render_post" do
    it "runs the string through Renderer" do
      allow(Renderer).to receive(:render).with("foo").and_return("bar")
      expect(helper.render_post("foo")).to eq("bar")
    end
  end
end
