require "spec_helper"

describe Exchange do
  # Create the first admin user
  before { create(:user) }

  let(:exchange) do
    create(:exchange, title: "This is my Discussion", body: "First post!")
  end
  let(:nsfw_exchange) { create(:exchange, nsfw: true) }
  let(:user) { create(:user) }
  let(:trusted_user) { create(:trusted_user) }
  let(:moderator) { create(:moderator) }
  let(:user_admin) { create(:user_admin) }
  let(:admin) { create(:admin) }

  it { is_expected.to belong_to(:poster).class_name("User") }
  it { is_expected.to belong_to(:closer).class_name("User") }
  it { is_expected.to belong_to(:last_poster).class_name("User") }
  it { is_expected.to have_many(:posts).dependent(:destroy) }
  it { is_expected.to have_many(:exchange_views).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to ensure_length_of(:title).is_at_most(100) }
  it { is_expected.to validate_presence_of(:body) }

  describe "#updated_by" do
    it "changes closer when updating" do
      expect do
        exchange.update_attributes(closed: true, updated_by: moderator)
      end.to change { exchange.closer }.from(nil).to(moderator)
    end
  end

  describe "#last_page" do
    before do
      3.times { create(:post, exchange: exchange) }
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
    specify { expect(Exchange.new.labels?).to eq(false) }
    specify { expect(Exchange.new(trusted: true).labels?).to eq(true) }
    specify { expect(Exchange.new(sticky: true).labels?).to eq(true) }
    specify { expect(Exchange.new(closed: true).labels?).to eq(true) }
    specify { expect(Exchange.new(nsfw: true).labels?).to eq(true) }
  end

  describe "#labels" do
    specify { expect(Exchange.new.labels).to eq([]) }
    specify { expect(Exchange.new(trusted: true).labels).to eq(["Trusted"]) }
    specify { expect(Exchange.new(sticky: true).labels).to eq(["Sticky"]) }
    specify { expect(Exchange.new(closed: true).labels).to eq(["Closed"]) }
    specify { expect(Exchange.new(nsfw: true).labels).to eq(["NSFW"]) }
    specify do
      expect(
        Exchange.new(
          trusted: true, sticky: true, closed: true, nsfw: true
        ).labels
      ).to eq(["Trusted", "Sticky", "Closed", "NSFW"])
    end
  end

  describe "#to_param" do
    subject { exchange.to_param }
    it { is_expected.to match(/^[\d]+-This\-is\-my\-Discussion$/) }
  end

  describe "#closeable_by?" do
    specify { expect(exchange.closeable_by?(user)).to eq(false) }

    context "when not closed" do
      specify { expect(exchange.closeable_by?(exchange.poster)).to eq(true) }
      specify { expect(exchange.closeable_by?(moderator)).to eq(true) }
    end

    context "when closed by the poster" do
      subject { exchange }

      before do
        exchange.update_attributes(closed: true, updated_by: exchange.poster)
      end

      specify { expect(exchange.closeable_by?(exchange.poster)).to eq(true) }
      specify { expect(exchange.closeable_by?(moderator)).to eq(true) }
      specify { expect(subject.closer).to eq(exchange.poster) }
    end

    context "closed by moderator" do
      subject { exchange }
      before { exchange.update_attributes(closed: true, updated_by: moderator) }
      specify { expect(exchange.closeable_by?(exchange.poster)).to eq(false) }
      specify { expect(exchange.closeable_by?(moderator)).to eq(true) }
      specify { expect(subject.closer).to eq(moderator) }
    end
  end

  describe "#validate_closed" do
    before do
      exchange.update_attributes(closed: true, updated_by: moderator)
    end

    subject { exchange }

    context "with no updated_by" do
      before do
        exchange.update_attributes(closed: false)
        exchange.valid?
      end
      it { is_expected.to be_valid }
      specify { expect(exchange.errors[:closed]).to eq([]) }
    end

    context "with updated_by poster" do
      before do
        exchange.update_attributes(closed: false, updated_by: exchange.poster)
        exchange.valid?
      end
      it { is_expected.to_not be_valid }
      specify { expect(exchange.errors[:closed].length).to eq(1) }
    end

    context "with updated_by moderator" do
      before do
        exchange.update_attributes(closed: false, updated_by: moderator)
        exchange.valid?
      end
      it { is_expected.to be_valid }
      specify { expect(exchange.errors[:closed]).to eq([]) }
    end
  end

  describe "#create_first_post" do
    subject { exchange.posts.first }
    specify { expect(subject.body).to eq("First post!") }
    specify { expect(subject.user).to eq(exchange.poster) }
  end

  describe "#update_post_body" do
    before { exchange.update_attributes(body: "changed post") }
    subject { exchange.posts.first }
    specify { expect(subject.body).to eq("changed post") }
  end
end
