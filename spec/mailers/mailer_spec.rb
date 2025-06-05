# frozen_string_literal: true

require "rails_helper"

describe Mailer do
  let(:user)      { create(:user) }
  let(:invite)    { create(:invite) }
  let(:login_url) { "http://example.com/login" }

  before do
    B3S.config.forum_name = "B3S"
    B3S.config.mail_sender = "test@example.com"
  end

  describe "invite" do
    let(:mail) { described_class.invite(invite, login_url) }

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
      it { is_expected.to match(login_url) }
      it { is_expected.to match("My message") }
    end
  end

  describe "new_user" do
    let(:mail) { described_class.new_user(user, login_url) }

    specify { expect(mail.subject).to eq("Welcome to B3S!") }
    specify { expect(mail.to).to eq([user.email]) }
    specify { expect(mail.from).to eq(["test@example.com"]) }

    describe "its body" do
      subject { mail.body.encoded }

      it { is_expected.to match(user.username) }
      it { is_expected.to match(login_url) }
    end
  end

  describe "password_reset" do
    subject { mail }

    let(:mail) do
      described_class.password_reset("user@example.com", "http://example.com")
    end

    specify { expect(mail.subject).to eq("Password reset for B3S") }
    specify { expect(mail.to).to eq(["user@example.com"]) }
    specify { expect(mail.from).to eq(["test@example.com"]) }
    specify { expect(mail.body.encoded).to match("http://example.com") }
  end
end
