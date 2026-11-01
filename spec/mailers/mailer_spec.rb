# frozen_string_literal: true

require "rails_helper"

describe Mailer do
  let(:user)   { create(:user) }
  let(:invite) { create(:invite) }

  before do
    B3S.config.forum_name = "B3S"
    B3S.config.mail_sender = "test@example.com"
  end

  describe "email_changed" do
    let(:mail) { described_class.email_changed(user, "old@example.com") }

    specify do
      expect(mail.subject).to eq("Your email address on B3S has changed")
    end

    specify { expect(mail.to).to eq(["old@example.com"]) }
    specify { expect(mail.from).to eq(["test@example.com"]) }

    describe "its body" do
      subject { mail.body.encoded }

      it { is_expected.to match(user.username) }
      it { is_expected.not_to include(user.email) }
      it { is_expected.to match("contact the moderators") }
    end
  end

  describe "invite" do
    let(:mail) { described_class.invite(invite) }

    specify do
      expect(
        mail.subject
      ).to eq("#{invite.user.realname} has invited you to B3S!")
    end

    specify { expect(mail.to).to eq([invite.email]) }
    specify { expect(mail.from).to eq(["test@example.com"]) }

    describe "its body" do
      subject { mail.body.encoded }

      let(:invite) { create(:invite, message: "My message") }

      it { is_expected.to match(B3S.config.forum_name) }
      it { is_expected.to match(invite.user.realname) }
      it { is_expected.to include("http://example.com/invites/accept?token=#{invite.token}") }
      it { is_expected.to match("My message") }
    end
  end

  describe "new_user" do
    let(:mail) { described_class.new_user(user) }

    specify { expect(mail.subject).to eq("Welcome to B3S!") }
    specify { expect(mail.to).to eq([user.email]) }
    specify { expect(mail.from).to eq(["test@example.com"]) }

    describe "its body" do
      subject { mail.body.encoded }

      it { is_expected.to match(user.username) }
      it { is_expected.to include("http://example.com/session/new") }
    end
  end

  describe "password_reset" do
    subject { mail }

    let(:user) { create(:user) }
    let(:mail) { described_class.password_reset(user) }

    specify { expect(mail.subject).to eq("Password reset for B3S") }
    specify { expect(mail.to).to eq([user.email]) }
    specify { expect(mail.from).to eq(["test@example.com"]) }

    describe "its reset link" do
      subject(:token) do
        url = mail.body.encoded[%r{http://example\.com/password_reset\?\S+}]
        Rack::Utils.parse_query(URI.parse(url).query)["token"]
      end

      it "resolves to the user" do
        expect(User.find_by_token_for(:password_reset, token)).to eq(user)
      end
    end
  end

  context "with the production URL options" do
    around do |example|
      original = ActionMailer::Base.default_url_options
      ActionMailer::Base.default_url_options = B3s::Application::MAILER_URL_OPTIONS
      example.run
    ensure
      ActionMailer::Base.default_url_options = original
    end

    it "links invites to https://b3s.me" do
      expect(described_class.invite(invite).body.encoded)
        .to include("https://b3s.me/invites/accept?token=#{invite.token}")
    end

    it "links new users to https://b3s.me" do
      expect(described_class.new_user(user).body.encoded)
        .to include("https://b3s.me/session/new")
    end

    it "links password resets to https://b3s.me" do
      expect(described_class.password_reset(user).body.encoded)
        .to match(%r{https://b3s\.me/password_reset\?token=\S+})
    end
  end
end
