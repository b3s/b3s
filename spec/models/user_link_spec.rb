# frozen_string_literal: true

require "rails_helper"

describe UserLink do
  subject(:user_link) { build(:user_link) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:label) }

  describe "url validation" do
    it { is_expected.to allow_value("example.photography").for(:url) }
    it { is_expected.to allow_value("example.bar").for(:url) }
    it { is_expected.to allow_value("https://example.online/path").for(:url) }
    it { is_expected.to allow_value("http://sub.example.co.uk").for(:url) }
    it { is_expected.to allow_value("example.com/foo/bar?baz=1").for(:url) }
    it { is_expected.to allow_value("https://xn--e1afmkfd.xn--p1ai").for(:url) }
    it { is_expected.to allow_value("example.xn--p1ai").for(:url) }
    it { is_expected.to allow_value("XN--E1AFMKFD.XN--P1AI").for(:url) }
    it { is_expected.to allow_value("https://de.wikipedia.org/wiki/Müller").for(:url) }
    it { is_expected.to allow_value("").for(:url) }

    it { is_expected.not_to allow_value("example.comm").for(:url) }
    it { is_expected.not_to allow_value("localhost").for(:url) }
    it { is_expected.not_to allow_value("http://localhost/path").for(:url) }
    it { is_expected.not_to allow_value("example.notatld").for(:url) }
    it { is_expected.not_to allow_value("co.uk").for(:url) }
    it { is_expected.not_to allow_value("javascript:alert(1)").for(:url) }
    it { is_expected.not_to allow_value("example").for(:url) }

    it do
      expect(user_link).not_to allow_value("example.comm")
        .for(:url).with_message(:invalid_domain)
    end

    context "without a name" do
      subject(:user_link) { build(:user_link, name: nil) }

      it { is_expected.not_to allow_value("").for(:url) }
    end
  end

  describe ".labels" do
    subject { described_class.labels }

    before do
      create(:user_link, label: "Service A")
      create(:user_link, label: "Service B")
      create(:user_link, label: "service A")
    end

    it { is_expected.to eq(["Service A", "Service B"]) }
  end

  describe ".with_label" do
    subject(:links) { described_class.with_label("Service A") }

    before do
      create(:user_link, label: "Service A")
      create(:user_link, label: "Service B")
      create(:user_link, label: "service A")
    end

    specify { expect(links.count).to eq(2) }
  end
end
