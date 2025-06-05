# frozen_string_literal: true

require "rails_helper"

describe Post do
  let(:exchange) { create(:discussion) }
  let(:post) { create(:post) }
  let(:user) { create(:user) }
  let(:cache_path) do
    Rails.public_path.join("cache", "discussions", exchange.id.to_s, "posts",
                           "count.json")
  end

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:exchange) }
  it { is_expected.to have_many(:exchange_views) }

  describe "after_create" do
    let(:post) { create(:post, exchange:) }

    specify do
      expect(post.user.participated_discussions).to include(exchange)
    end

    describe "the discussion it belongs to" do
      before { post }

      specify { expect(exchange.last_poster).to eq(post.user) }
      specify { expect(exchange.last_post_at).to eq(post.created_at) }
    end

    describe "updating posts count" do
      let!(:exchange) { create(:discussion) }
      let(:post) { create(:post, user:, exchange:) }

      it "increments public_posts_count on user" do
        expect { post }.to change(user, :public_posts_count).by(1)
      end

      it "increments posts_count on user" do
        expect { post }.to change(user, :posts_count).by(1)
      end

      it "increments posts_count on exchange" do
        expect { post }.to change(exchange, :posts_count).by(1)
      end
    end
  end

  describe "after_destroy" do
    describe "updating posts count" do
      let!(:post) { create(:post, user:, exchange:) }

      it "decrements public_posts_count on user" do
        expect { post.destroy }.to change(user, :public_posts_count).by(-1)
      end

      it "decrements posts_count on user" do
        expect { post.destroy }.to change(user, :posts_count).by(-1)
      end

      it "decrements posts_count on exchange" do
        expect { post.destroy }.to change(exchange, :posts_count).by(-1)
      end
    end
  end

  describe "#me_post?" do
    subject { post.me_post? }

    context "when post starts with /me" do
      let(:post) { create(:post, body: "/me shuffles") }

      it { is_expected.to be(true) }
    end

    context "when post starts with /me and contains a line break" do
      let(:post) { create(:post, body: "/me shuffles\noh yeah") }

      it { is_expected.to be_falsey }
    end

    context "when post doesn't start with /me" do
      let(:post) { create(:post, body: "Start with /me") }

      it { is_expected.to be_falsey }
    end
  end

  describe "#post_number" do
    specify { expect(exchange.posts.first.post_number).to eq(1) }
    specify { expect(create(:post, exchange:).post_number).to eq(2) }
  end

  describe "#page" do
    subject { post.page }

    context "when it's the first post" do
      before { allow(post).to receive(:post_number).and_return(1) }

      it { is_expected.to eq(1) }
    end

    context "when it's the last post on a page" do
      before { allow(post).to receive(:post_number).and_return(50) }

      it { is_expected.to eq(1) }
    end

    context "when it's the first post on the second page" do
      before { allow(post).to receive(:post_number).and_return(51) }

      it { is_expected.to eq(2) }
    end

    context "with :limit set" do
      subject { post.page(limit: 10) }

      before { allow(post).to receive(:post_number).and_return(70) }

      it { is_expected.to eq(7) }
    end
  end

  describe "#body_html" do
    subject { post.body_html }

    let!(:post) { create(:post, exchange:) }

    it { is_expected.to eq(Renderer.render(post.body)) }

    context "when not saved" do
      let!(:post) { build(:post, exchange:) }

      before { allow(Renderer).to receive(:render) }

      it "parses the post" do
        post.body_html
        expect(Renderer).to have_received(:render).once
      end
    end

    context "when body_html has been set" do
      let!(:post) do
        create(:post, exchange:, body_html: "<p>Test</p>")
      end

      before { allow(Renderer).to receive(:render) }

      it "uses the cached version" do
        post.body_html
        expect(Renderer).to have_received(:render).exactly(0).times
      end
    end

    context "when body_html hasn't been set" do
      before do
        allow(Renderer).to(receive(:render).and_return("<p>Test</p>"))
      end

      it "parses the post" do
        post.body_html = nil
        post.body_html
        expect(Renderer).to have_received(:render).once
      end
    end
  end

  describe "#edited?" do
    subject { post.edited? }

    context "when post hasn't been edited" do
      it { is_expected.to be(false) }
    end

    context "when post has been edited" do
      let(:post) do
        create(:post, created_at: 5.minutes.ago, edited_at: 2.minutes.ago)
      end

      it { is_expected.to be(true) }
    end

    context "when post has been edited less than five seconds ago" do
      let(:post) do
        create(:post, created_at: 14.seconds.ago, edited_at: 10.seconds.ago)
      end

      it { is_expected.to be(false) }
    end
  end

  describe "#editable_by?" do
    specify { expect(post.editable_by?(post.user)).to be(true) }
    specify { expect(post.editable_by?(create(:user, :moderator))).to be(true) }
    specify { expect(post.editable_by?(create(:user, :admin))).to be(true) }
    specify { expect(post.editable_by?(user)).to be(false) }
    specify { expect(post.editable_by?(nil)).to be(false) }

    specify do
      expect(post.editable_by?(create(:user, :user_admin))).to be(false)
    end
  end

  describe "#viewable_by?" do
    specify { expect(post.viewable_by?(user)).to be(true) }

    context "when public browsing is on" do
      before { B3S.config.public_browsing = true }

      specify { expect(post.viewable_by?(nil)).to be(true) }
    end

    context "when public browsing is off" do
      before { B3S.config.public_browsing = false }

      specify { expect(post.viewable_by?(nil)).to be(false) }
    end
  end

  describe "#mentions_users?" do
    subject { post.mentions_users? }

    context "when it doesn't mention users" do
      it { is_expected.to be(false) }
    end

    context "when it mentions users" do
      let(:mentioned_users) do
        ["eléktronaut", "#1", "With space"].map do |u|
          create(:user, username: u)
        end
      end

      let(:post) do
        create(
          :post,
          body: mentioned_users.map do |u|
                  "@#{u.username.downcase}"
                end.join(" and ")
        )
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#mentioned_users" do
    subject { post.mentioned_users }

    context "when it doesn't mention users" do
      it { is_expected.to eq([]) }
    end

    context "when it mentions users" do
      let(:mentioned_users) do
        ["eléktronaut", "#1", "With space"].map do |u|
          create(:user, username: u)
        end
      end
      let(:post) do
        create(
          :post,
          body: mentioned_users.map do |u|
                  "@#{u.username.downcase}"
                end.join(" and ")
        )
      end

      it { is_expected.to match_array(mentioned_users) }
    end
  end

  describe "#render_html" do
    let!(:exchange) { create(:discussion) }

    context "when skip_html is false" do
      it "parses the post" do
        allow(Renderer).to receive(:render)
        create(:post, exchange:)
        expect(Renderer).to have_received(:render).once
      end
    end

    context "when skip_html is true" do
      it "parses the post" do
        allow(Renderer).to receive(:render)
        create(:post, skip_html: true, exchange:)
        expect(Renderer).not_to have_received(:render)
      end
    end
  end

  describe "#set_edit_timestamp" do
    context "when edited_at is set" do
      let(:timestamp) { 2.days.ago }
      let(:post) { create(:post, edited_at: timestamp) }

      specify { expect(post.edited_at).to be_within(1.second).of(timestamp) }
    end

    context "when edited_at isn't set" do
      before do
        allow(Time).to receive(:now)
          .and_return(Time.zone.parse("Oct 22 2012"))
      end

      specify { expect(post.edited_at).to eq(Time.now.utc) }
    end
  end

  describe "#define_relationship" do
    context "when it belongs to a discussion" do
      let!(:exchange) { create(:discussion) }

      it "defines a relationship between the discussion and the poster" do
        allow(DiscussionRelationship).to receive(:define)
        create(:post, user:, exchange:)
        expect(DiscussionRelationship).to(
          have_received(:define).once.with(user, exchange, participated: true)
        )
      end
    end

    context "when it belongs to a conversation" do
      let!(:exchange) { create(:conversation) }

      it "does not define a relationship" do
        allow(DiscussionRelationship).to receive(:define)
        create(:post, exchange:)
        expect(DiscussionRelationship).not_to have_received(:define)
      end
    end
  end

  describe "#update_exchange" do
    subject(:exchange) { post.exchange }

    specify { expect(exchange.last_poster_id).to eq(post.user_id) }
    specify { expect(exchange.last_post_at).to eq(post.created_at) }
  end
end
