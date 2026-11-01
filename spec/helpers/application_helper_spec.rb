# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper do
  describe "#pretty_link" do
    subject { helper.pretty_link(url) }

    context "when URL lacks http://" do
      let(:url) { "example.com" }

      it { is_expected.to eq('<a href="http://example.com">example.com</a>') }
    end

    context "when URL is valid" do
      let(:url) { "https://ex.com/" }

      it { is_expected.to eq('<a href="https://ex.com">ex.com</a>') }
    end

    context "when URL has a path" do
      let(:url) { "https://ex.com/foo/" }
      let(:link) { '<a href="https://ex.com/foo/">ex.com/foo/</a>' }

      it { is_expected.to eq(link) }
    end
  end

  describe "#possessive" do
    subject { helper.possessive(noun) }

    context "when word ends with 's'" do
      let(:noun) { "Charles" }

      it { is_expected.to eq("Charles'") }
    end

    context "when word doesn't end with 's'" do
      let(:noun) { "Inge" }

      it { is_expected.to eq("Inge's") }
    end
  end

  describe "#profile_link" do
    subject { helper.profile_link(user) }

    let(:user) { build(:user, username: "foo") }

    context "when user is nil" do
      let(:user) { nil }

      it { is_expected.to eq("Unknown") }
    end

    context "when user exists" do
      let(:link) do
        '<a title="foo&#39;s profile" href="/users/profile/foo">foo</a>'
      end

      it { is_expected.to eq(link) }
    end

    context "when link text is set" do
      subject { helper.profile_link(user, "Profile") }

      let(:link) do
        '<a title="foo&#39;s profile" href="/users/profile/foo">Profile</a>'
      end

      it { is_expected.to eq(link) }
    end
  end

  describe "#user_link" do
    subject { helper.user_link(link) }

    context "when the URL has no scheme" do
      let(:link) { build(:user_link, name: nil, url: "example.com/foo") }
      let(:html) { '<a href="https://example.com/foo">example.com/foo</a>' }

      it { is_expected.to eq(html) }
    end

    context "when the URL has a non-http scheme" do
      let(:link) { build(:user_link, name: nil, url: "javascript:alert(1)") }

      it { is_expected.to eq("javascript:alert(1)") }
    end

    context "without a URL" do
      let(:link) { build(:user_link, name: "foo", url: "") }

      it { is_expected.to eq("foo") }
    end
  end
end
