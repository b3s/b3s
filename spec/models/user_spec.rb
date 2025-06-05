# encoding: utf-8
# frozen_string_literal: true

require "rails_helper"

describe User do
  subject(:user) { build(:user) }

  let(:admin) { build(:user, :admin) }
  let(:moderator) { build(:user, :moderator) }
  let(:user_admin) { build(:user, :user_admin) }
  let(:public_attributes) do
    %w[admin banned_until created_at description id inviter_id last_active
       latitude location longitude moderator realname user_admin username
       status]
  end

  it { is_expected.to be_a(Authenticable) }
  it { is_expected.to be_a(Inviter) }
  it { is_expected.to be_a(ExchangeParticipant) }
  it { is_expected.to be_a(UserScopes) }

  it { is_expected.to belong_to(:avatar).dependent(:destroy).optional }
  it { is_expected.to have_many(:exchange_moderators).dependent(:destroy) }
  it { is_expected.to have_many(:user_links).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:username) }

  specify do
    expect(user).to validate_uniqueness_of(:username)
      .case_insensitive.with_message(/is already registered/)
  end

  it { is_expected.to allow_value("Gustave Moíre").for(:username) }
  it { is_expected.not_to allow_value("").for(:username) }
  it { is_expected.not_to allow_value("elektronaut?admin=1").for(:username) }

  specify do
    expect(user).to validate_uniqueness_of(:email)
      .case_insensitive.with_message(/is already registered/)
  end

  it { is_expected.to allow_value("test@example.com").for(:email) }
  it { is_expected.not_to allow_value("test.example.com").for(:email) }
  it { is_expected.to validate_presence_of(:email) }

  it "accepts a valid url for stylesheet_url" do
    expect(user).to(
      allow_value("https://example.com/stylesheet.css").for(:stylesheet_url)
    )
  end

  it "does not accept invalid values for stylesheet_url" do
    expect(user).not_to(
      allow_value("invalid").for(:stylesheet_url)
    )
  end

  it "accepts a valid url for mobile_stylesheet_url" do
    expect(user).to(
      allow_value("https://example.com/stylesheet.css").for(:mobile_stylesheet_url)
    )
  end

  it "does not accept invalid values for mobile_stylesheet_url" do
    expect(user).not_to(
      allow_value("invalid").for(:mobile_stylesheet_url)
    )
  end

  describe "#name_and_email" do
    subject { user.name_and_email }

    context "when realname is set" do
      let(:user) { build(:user, realname: "John") }

      it { is_expected.to eq("#{user.realname} <#{user.email}>") }
    end

    context "when realname isn't set" do
      let(:user) { build(:user, realname: nil) }

      it { is_expected.to eq(user.email.to_s) }
    end
  end

  describe "#previous_usernames" do
    subject { user.previous_usernames }

    let(:user) { create(:user, username: "originalname") }

    context "when username hasn't been changed" do
      it { is_expected.to eq([]) }
    end

    context "when username changes" do
      before { user.update(username: "newname") }

      it { is_expected.to eq(["originalname"]) }
    end
  end

  describe "#realname_or_username" do
    subject { user.realname_or_username }

    context "when realname is set" do
      let(:user) { build(:user, realname: "John") }

      it { is_expected.to eq(user.realname) }
    end

    context "when realname isn't set" do
      let(:user) { build(:user, realname: nil) }

      it { is_expected.to eq(user.username) }
    end
  end

  describe "#online?" do
    subject { user.online? }

    context "when user is online" do
      let(:user) { build(:user, last_active: 2.minutes.ago) }

      it { is_expected.to be(true) }
    end

    context "when user is offline" do
      let(:user) { build(:user, last_active: 2.days.ago) }

      it { is_expected.to be(false) }
    end
  end

  describe "#user_admin?" do
    specify { expect(user_admin.user_admin?).to be(true) }
    specify { expect(admin.user_admin?).to be(true) }
    specify { expect(moderator.user_admin?).to be(false) }
  end

  describe "#moderator?" do
    specify { expect(moderator.moderator?).to be(true) }
    specify { expect(admin.moderator?).to be(true) }
    specify { expect(user_admin.moderator?).to be(false) }
  end

  describe "#admin_labels" do
    specify { expect(admin.admin_labels).to eq(["Admin"]) }
    specify { expect(user_admin.admin_labels).to eq(["User Admin"]) }
    specify { expect(moderator.admin_labels).to eq(["Moderator"]) }

    specify do
      expect(
        build(:user, moderator: true, user_admin: true).admin_labels
      ).to eq(["User Admin", "Moderator"])
    end

    specify { expect(user.admin_labels).to eq([]) }
  end

  describe "#theme" do
    before { B3S.config.default_theme = "default" }

    specify { expect(user.theme).to eq("default") }
    specify { expect(create(:user, theme: "mytheme").theme).to eq("mytheme") }
  end

  describe "#mark_active!" do
    subject { user.last_active }

    before { user.mark_active! }

    context "when user hasn't signed in yet" do
      let(:user) { create(:user, last_active: nil) }

      it { is_expected.to be_within(1.0).of(Time.now.utc) }
    end

    context "when user has been active" do
      let(:user) { create(:user, last_active: 2.days.ago) }

      it { is_expected.to be_within(1.0).of(Time.now.utc) }
    end

    context "when user has been active in the last 10 minutes" do
      let(:user) { create(:user, last_active: 5.minutes.ago) }

      it { is_expected.to be_within(1.0).of(5.minutes.ago) }
    end
  end

  describe "#mobile_theme" do
    subject { user.mobile_theme }

    before { B3S.config.default_mobile_theme = "default_mobile" }

    context "when not set" do
      it { is_expected.to eq("default_mobile") }
    end

    context "when set" do
      let(:user) { build(:user, mobile_theme: "mytheme_mobile") }

      it { is_expected.to eq("mytheme_mobile") }
    end
  end

  describe "#as_json" do
    let(:keys) { user.as_json.keys.map(&:to_s) }

    it "only includes public information" do
      expect(keys).to match_array(public_attributes)
    end
  end

  describe "#ensure_last_active_is_set" do
    subject { create(:user).last_active }

    it { is_expected.to be_a(Time) }
  end
end
