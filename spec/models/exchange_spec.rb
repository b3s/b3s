# frozen_string_literal: true

require "rails_helper"

describe Exchange do
  # Create the first admin user
  before { create(:user) }

  let(:exchange) do
    create(:exchange, title: "This is my Discussion", body: "First post!")
  end
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let(:admin) { create(:user, :admin) }

  it { is_expected.to belong_to(:poster).class_name("User") }
  it { is_expected.to belong_to(:closer).class_name("User").optional }
  it { is_expected.to belong_to(:last_poster).class_name("User").optional }
  it { is_expected.to have_many(:posts).dependent(:destroy) }
  it { is_expected.to have_many(:exchange_views).dependent(:destroy) }

  it { is_expected.to have_many(:exchange_moderators).dependent(:destroy) }
  it { is_expected.to have_many(:exchange_moderator_users) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:title).is_at_most(100) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_length_of(:body).is_at_most(100_000) }

  describe "#updated_by" do
    it "changes closer when updating" do
      expect do
        exchange.update(closed: true, updated_by: moderator)
      end.to change(exchange, :closer).from(nil).to(moderator)
    end
  end

  describe "#last_page" do
    before do
      create_list(:post, 3, exchange:)
      exchange.reload
    end

    context "without arguments" do
      subject { exchange.last_page }

      it { is_expected.to eq(1) }
    end

    context "with argument" do
      subject { exchange.last_page(2) }

      it { is_expected.to eq(2) }
    end
  end

  describe "#labels?" do
    specify { expect(described_class.new.labels?).to be(false) }
    specify { expect(described_class.new(sticky: true).labels?).to be(true) }
    specify { expect(described_class.new(closed: true).labels?).to be(true) }
    specify { expect(described_class.new(nsfw: true).labels?).to be(true) }
  end

  describe "#labels" do
    specify { expect(described_class.new.labels).to eq([]) }

    specify do
      expect(described_class.new(sticky: true).labels).to eq(["Sticky"])
    end

    specify do
      expect(described_class.new(closed: true).labels).to eq(["Closed"])
    end

    specify do
      expect(described_class.new(nsfw: true).labels).to eq(["NSFW"])
    end

    specify do
      expect(
        described_class.new(
          sticky: true, closed: true, nsfw: true
        ).labels
      ).to eq(%w[Sticky Closed NSFW])
    end
  end

  describe "#moderators" do
    subject { exchange.moderators }

    context "without any moderators" do
      it { is_expected.to contain_exactly(exchange.poster) }
    end

    context "with moderators" do
      let(:moderator) { create(:user) }

      before do
        exchange.exchange_moderators.create(user: exchange.poster)
        exchange.exchange_moderators.create(user: moderator)
      end

      it { is_expected.to contain_exactly(exchange.poster, moderator) }
    end
  end

  describe "#moderators?" do
    subject { exchange.moderators? }

    context "without any moderators" do
      it { is_expected.to be(false) }
    end

    context "with moderators" do
      before { create(:exchange_moderator, exchange:) }

      it { is_expected.to be(true) }
    end
  end

  describe "#to_param" do
    subject { exchange.to_param }

    it { is_expected.to match(/^\d+-This-is-my-Discussion$/) }
  end

  describe "#closeable_by?" do
    let(:exchange_moderator) do
      create(:exchange_moderator, exchange:).user
    end

    specify { expect(exchange.closeable_by?(user)).to be(false) }

    context "when not closed" do
      specify { expect(exchange.closeable_by?(exchange.poster)).to be(true) }
      specify { expect(exchange.closeable_by?(moderator)).to be(true) }
      specify { expect(exchange.closeable_by?(exchange_moderator)).to be(true) }
    end

    context "when closed by the poster" do
      before do
        exchange.update(closed: true, updated_by: exchange.poster)
      end

      specify { expect(exchange.closeable_by?(exchange.poster)).to be(true) }
      specify { expect(exchange.closeable_by?(exchange_moderator)).to be(true) }
      specify { expect(exchange.closeable_by?(moderator)).to be(true) }
      specify { expect(exchange.closer).to eq(exchange.poster) }
    end

    context "when closed by moderator" do
      before { exchange.update(closed: true, updated_by: moderator) }

      specify { expect(exchange.closeable_by?(exchange.poster)).to be(false) }
      specify { expect(exchange.closeable_by?(moderator)).to be(true) }
      specify { expect(exchange.closer).to eq(moderator) }

      it "is not closeable by an exchange moderator" do
        expect(exchange.closeable_by?(exchange_moderator)).to be(false)
      end
    end

    context "when closed by exchange moderator" do
      before do
        exchange.update(closed: true, updated_by: exchange_moderator)
      end

      specify { expect(exchange.closeable_by?(exchange.poster)).to be(true) }
      specify { expect(exchange.closeable_by?(exchange_moderator)).to be(true) }
      specify { expect(exchange.closeable_by?(moderator)).to be(true) }
      specify { expect(exchange.closer).to eq(exchange_moderator) }
    end
  end

  describe "#validate_closed" do
    subject { exchange }

    before do
      exchange.update(closed: true, updated_by: moderator)
    end

    context "with no updated_by" do
      before do
        exchange.update(closed: false)
        exchange.valid?
      end

      it { is_expected.to be_valid }
      specify { expect(exchange.errors[:closed]).to eq([]) }
    end

    context "with updated_by poster" do
      before do
        exchange.update(closed: false, updated_by: exchange.poster)
        exchange.valid?
      end

      it { is_expected.not_to be_valid }
      specify { expect(exchange.errors[:closed].length).to eq(1) }
    end

    context "with updated_by moderator" do
      before do
        exchange.update(closed: false, updated_by: moderator)
        exchange.valid?
      end

      it { is_expected.to be_valid }
      specify { expect(exchange.errors[:closed]).to eq([]) }
    end
  end

  describe "#create_first_post" do
    let(:first_post) { exchange.posts.first }

    specify { expect(first_post.body).to eq("First post!") }
    specify { expect(first_post.user).to eq(exchange.poster) }
  end

  describe "#unlabel!" do
    let(:exchange) do
      create(:discussion, sticky: true, closed: true, nsfw: true)
    end

    before { exchange.unlabel! }

    specify { expect(exchange.sticky?).to be(false) }
    specify { expect(exchange.closed?).to be(false) }
    specify { expect(exchange.nsfw?).to be(false) }
  end

  describe "#update_post_body" do
    let(:first_post) { exchange.posts.first }

    before { exchange.update(body: "changed post") }

    specify { expect(first_post.body).to eq("changed post") }

    context "when the body is over the length limit" do
      before { exchange.update(body: "a" * 100_001) }

      specify { expect(exchange.errors).to be_of_kind(:body, :too_long) }
      specify { expect(first_post.reload.body).to eq("changed post") }
    end

    context "when validating without a body" do
      it "does not query the posts" do
        reloaded = described_class.find(exchange.id)
        expect(count_queries(matching: 'FROM "posts"') { reloaded.valid? }).to eq(0)
      end
    end

    context "when the existing body is over the length limit" do
      before do
        first_post.body = "a" * 100_001
        first_post.save!(validate: false)
      end

      specify { expect(exchange.update(title: "New title", body: "a" * 100_001)).to be(true) }
      specify { expect(exchange.update(title: "New title")).to be(true) }
    end
  end
end
