# frozen_string_literal: true

require "rails_helper"

describe AvatarsHelper do
  describe "#avatar_image_tag" do
    subject { helper.avatar_image_tag(user) }

    let(:svg) do
      Base64.decode64(Nokogiri::HTML.fragment(subject).at("img")["src"]
                        .delete_prefix("data:image/svg+xml;base64,"))
    end

    context "when user has an avatar uploaded" do
      let(:user) { create(:user, :with_avatar, username: "foo") }
      let(:expression) do
        Regexp.new('<img alt="foo" class="avatar-image" ' \
                   'src="\/avatars\/(.+)\/16x16\/([\d])+-([\d])+\.png" ' \
                   'width="16" height="16" \/>')
      end

      it { is_expected.to match(expression) }
    end

    context "when user has no avatar" do
      let(:user) { create(:user, username: "foo", email: "foo@example.com") }
      let(:expression) do
        Regexp.new('\A<img alt="foo" class="avatar-image" ' \
                   'src="data:image/svg\+xml;base64,[A-Za-z0-9+/=]+" ' \
                   'width="96" height="96" />\z')
      end

      it { is_expected.to match(expression) }
      it { is_expected.not_to include("gravatar") }
      it { is_expected.not_to include(Digest::MD5.hexdigest(user.email)) }
      it { expect(svg).to start_with("<svg ") }
      it { expect(svg).not_to include(user.email) }
      it { expect(svg).to match(/<path fill="hsl\(\d+,\d+%,\d+%\)"/) }
    end

    context "when rendering the same user twice" do
      let(:user) { create(:user) }

      it { is_expected.to eq(helper.avatar_image_tag(User.find(user.id))) }
    end

    context "when rendering different users" do
      let(:user) { create(:user) }

      it { is_expected.not_to eq(helper.avatar_image_tag(create(:user))) }
    end

    context "when user doesn't have an email set" do
      let(:user) { create(:user).tap { |u| u.email = nil } }

      it { is_expected.to include("data:image/svg+xml;base64,") }
    end
  end
end
