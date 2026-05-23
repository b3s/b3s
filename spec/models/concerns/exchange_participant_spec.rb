# frozen_string_literal: true

require "rails_helper"

describe ExchangeParticipant do
  subject(:user) { create(:user) }

  let(:discussion)   { create(:discussion) }
  let(:conversation) { create(:conversation) }

  it { is_expected.to have_many(:discussions) }
  it { is_expected.to have_many(:posts) }
  it { is_expected.to have_many(:discussion_posts).class_name("Post") }
  it { is_expected.to have_many(:exchange_views).dependent(:destroy) }
  it { is_expected.to have_many(:discussion_relationships).dependent(:destroy) }

  specify do
    expect(user).to have_many(:followed_discussions)
      .through(:discussion_relationships)
  end

  specify do
    expect(user).to have_many(:favorite_discussions)
      .through(:discussion_relationships)
  end

  specify do
    expect(user).to have_many(:hidden_discussions)
      .through(:discussion_relationships)
  end

  specify do
    expect(user).to have_many(:conversation_relationships)
      .dependent(:destroy)
  end

  specify do
    expect(user).to have_many(:conversations)
      .through(:conversation_relationships)
  end

  describe "#unhidden_discussions" do
    subject { user.unhidden_discussions }

    let!(:discussion) { create(:discussion) }
    let!(:hidden_discussion) { create(:discussion) }

    before do
      DiscussionRelationship.define(user, hidden_discussion, hidden: true)
    end

    it { is_expected.to contain_exactly(discussion) }
  end

  describe "#mark_exchange_viewed" do
    let(:post) { create(:post, exchange: discussion) }
    let(:exchange_view) { user.exchange_views.last }

    context "with existing exchange view" do
      before do
        create(:exchange_view, user:, exchange: discussion)
      end

      it "does not create a new view" do
        expect do
          user.mark_exchange_viewed(discussion, post, 2)
        end.not_to change(ExchangeView, :count)
      end

      it "sets the post index" do
        user.mark_exchange_viewed(discussion, post, 2)
        expect(exchange_view.post_index).to eq(2)
      end

      it "sets the post" do
        user.mark_exchange_viewed(discussion, post, 2)
        expect(exchange_view.post).to eq(post)
      end
    end

    context "without existing discussion view" do
      it "creates a new view" do
        expect do
          user.mark_exchange_viewed(discussion, post, 2)
        end.to change(ExchangeView, :count).by(1)
      end

      it "sets the post index" do
        user.mark_exchange_viewed(discussion, post, 2)
        expect(exchange_view.post_index).to eq(2)
      end

      it "sets the post" do
        user.mark_exchange_viewed(discussion, post, 2)
        expect(exchange_view.post).to eq(post)
      end
    end
  end

  describe "#mark_conversation_viewed" do
    let(:relationship) do
      user.conversation_relationships.where(conversation_id: conversation).first
    end

    let(:user) { conversation.poster }
    let(:conversation_relationship) do
      user.conversation_relationships.where(conversation_id: conversation).first
    end

    before do
      conversation_relationship.update(new_posts: true)
      user.mark_conversation_viewed(conversation)
    end

    it "marks the conversation as viewed" do
      expect(relationship.new_posts?).to be(false)
    end
  end

  describe "#posts_per_day" do
    subject { user.posts_per_day }

    let(:user) { create(:user, created_at: 3.days.ago) }

    before do
      create(:post, user:)
      user.reload
    end

    it { is_expected.to be_within(0.001).of(1.0 / 3.0) }
  end

  describe "#unread_conversations_count" do
    subject { user.unread_conversations_count }

    context "with no conversations" do
      it { is_expected.to eq(0) }
    end

    context "with conversations" do
      before do
        create(
          :conversation_relationship,
          user:,
          new_posts: true
        )
      end

      it { is_expected.to eq(1) }
    end
  end

  describe "#unread_conversations?" do
    subject { user.unread_conversations? }

    context "with no unread conversations" do
      it { is_expected.to be(false) }
    end

    context "with unread conversations" do
      before do
        create(
          :conversation_relationship,
          user:,
          new_posts: true
        )
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#muted_conversation?" do
    subject { user.muted_conversation?(conversation) }

    let(:conversation) { create(:conversation) }

    before { conversation.add_participant(user) }

    context "when conversation isn't muted" do
      it { is_expected.to be(false) }
    end

    context "when conversation is muted" do
      before do
        user.conversation_relationships
            .each { |cr| cr.update(notifications: false) }
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#discussion_relationship_with" do
    before { DiscussionRelationship.define(user, discussion, following: true) }

    it "memoizes the lookup per discussion" do
      user.discussion_relationship_with(discussion)
      queries = count_queries(matching: "discussion_relationships") do
        3.times { user.discussion_relationship_with(discussion) }
      end
      expect(queries).to eq(0)
    end
  end

  describe "#following?" do
    subject { user.following?(discussion) }

    context "when discussion isn't followed" do
      it { is_expected.to be(false) }
    end

    context "when discussion is followed" do
      before do
        DiscussionRelationship.define(user, discussion, following: true)
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#favorite?" do
    subject { user.favorite?(discussion) }

    context "when discussion isn't favorite" do
      it { is_expected.to be(false) }
    end

    context "when discussion is favorite" do
      before { DiscussionRelationship.define(user, discussion, favorite: true) }

      it { is_expected.to be(true) }
    end
  end

  describe "#hidden?" do
    subject { user.hidden?(discussion) }

    context "when discussion isn't hidden" do
      it { is_expected.to be(false) }
    end

    context "when discussion is hidden" do
      before { DiscussionRelationship.define(user, discussion, hidden: true) }

      it { is_expected.to be(true) }
    end
  end
end
