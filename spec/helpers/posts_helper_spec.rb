# frozen_string_literal: true

require "rails_helper"

describe PostsHelper do
  let(:user) { create(:user, username: "foo") }
  let(:profile_link) { helper.profile_link(user, nil, class: :poster) }

  let(:smile_image) do
    '<img alt="smile" class="emoji" ' \
      'src="/images/emoji/unicode/1f604.png" ' \
      'style="vertical-align:middle" ' \
      'width="16" height="16" />'
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
  end

  describe "#render_post" do
    it "runs the string through Renderer" do
      allow(Renderer).to receive(:render).with("foo").and_return("bar")
      expect(helper.render_post("foo")).to eq("bar")
    end
  end
end
