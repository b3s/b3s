# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

RSpec.describe Ability do
  let(:ability) { described_class.new(user) }

  describe "Authenticated user abilities" do
    # Create a dummy first user to prevent auto-admin promotion
    before { create(:user) if User.none? }

    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    describe "User management" do
      it { expect(ability).to be_able_to(:read, User.new) }
      it { expect(ability).to be_able_to(:update, user) }
      it { expect(ability).not_to be_able_to(:update, other_user) }
    end

    describe "Discussion management" do
      let(:discussion) { create(:discussion, poster: user) }
      let(:other_discussion) { create(:discussion, poster: other_user) }

      it { expect(ability).to be_able_to(:read, Discussion.new) }
      it { expect(ability).to be_able_to(:create, Discussion.new) }
      it { expect(ability).to be_able_to(:update, discussion) }
      it { expect(ability).not_to be_able_to(:update, other_discussion) }
      it { expect(ability).to be_able_to(:close, discussion) }
      it { expect(ability).not_to be_able_to(:close, other_discussion) }
    end

    describe "Discussion with exchange moderator" do
      let(:discussion) { create(:discussion, poster: other_user) }
      let!(:moderator) do
        ExchangeModerator.create(user:, exchange: discussion)
      end

      it { expect(ability).to be_able_to(:update, discussion) }
      it { expect(ability).to be_able_to(:close, discussion) }
    end

    describe "Conversation management" do
      let(:conversation) { create(:conversation, poster: user) }
      let(:other_conversation) { create(:conversation, poster: other_user) }

      before do
        # Add user as participant to their own conversation (automatic)
        # Add user as participant to other_conversation for testing
        other_conversation.add_participant(user)
      end

      it { expect(ability).to be_able_to(:create, Conversation.new) }
      it { expect(ability).to be_able_to(:read, conversation) }
      it { expect(ability).to be_able_to(:read, other_conversation) }
      it { expect(ability).to be_able_to(:update, conversation) }
      it { expect(ability).not_to be_able_to(:update, other_conversation) }
    end

    describe "Post management" do
      let(:post) { create(:post, user:) }
      let(:other_post) { create(:post, user: other_user) }

      it { expect(ability).to be_able_to(:read, Post.new) }
      it { expect(ability).to be_able_to(:update, post) }
      it { expect(ability).not_to be_able_to(:update, other_post) }
    end

    describe "Creating posts in discussions" do
      let(:open_discussion) { create(:discussion) }
      let(:closed_discussion) { create(:closed_discussion) }

      it "can post to open discussions" do
        post = Post.new(exchange: open_discussion)
        expect(ability).to be_able_to(:create, post)
      end

      it "cannot post to closed discussions" do
        post = Post.new(exchange: closed_discussion)
        expect(ability).not_to be_able_to(:create, post)
      end
    end

    describe "Creating posts in conversations" do
      let(:conversation) { create(:conversation, poster: other_user) }

      context "when user is a participant" do
        before { conversation.add_participant(user) }

        it "can post to the conversation" do
          post = Post.new(exchange: conversation)
          expect(ability).to be_able_to(:create, post)
        end
      end

      context "when user is not a participant" do
        it "cannot post to the conversation" do
          post = Post.new(exchange: conversation)
          expect(ability).not_to be_able_to(:create, post)
        end
      end
    end

    describe "Invite management" do
      let(:invite) { create(:invite, user:) }
      let(:other_invite) { create(:invite, user: other_user) }

      it { expect(ability).to be_able_to(:manage, invite) }
      it { expect(ability).not_to be_able_to(:manage, other_invite) }
      it { expect(ability).to be_able_to(:accept, Invite.new) }
    end

    describe "Discussion relationships" do
      let(:relationship) { DiscussionRelationship.new(user:) }
      let(:other_relationship) { DiscussionRelationship.new(user: other_user) }

      it { expect(ability).to be_able_to(:manage, relationship) }
      it { expect(ability).not_to be_able_to(:manage, other_relationship) }
    end

    describe "Conversation participant management" do
      let(:conversation) { create(:conversation, poster: user) }
      let(:participant) { create(:user) }
      let!(:relationship) do
        conversation.add_participant(participant)
        conversation.conversation_relationships.find_by(user: participant)
      end

      it "can remove participant when they are the poster" do
        expect(ability).to be_able_to(:destroy, relationship)
      end

      it "can remove themselves" do
        own_relationship = conversation.conversation_relationships.find_by(
          user:
        )
        expect(ability).to be_able_to(:destroy, own_relationship)
      end

      it "cannot remove others when not the poster" do
        other_conversation = create(:conversation, poster: other_user)
        other_conversation.add_participant(user)
        other_conversation.add_participant(participant)
        other_relationship = other_conversation.conversation_relationships.find_by(
          user: participant
        )
        expect(ability).not_to be_able_to(:destroy, other_relationship)
      end
    end

    describe "Uploads (PostImages)" do
      it { expect(ability).to be_able_to(:create, PostImage.new) }
    end
  end

  describe "Moderator abilities" do
    let(:user) { create(:user, :moderator) }
    let(:other_user) { create(:user) }

    it "inherits authenticated abilities" do
      expect(ability).to be_able_to(:read, Discussion.new)
      expect(ability).to be_able_to(:create, Discussion.new)
    end

    describe "Discussion management" do
      let(:discussion) { create(:discussion, poster: other_user) }

      it { expect(ability).to be_able_to(:update, discussion) }
      it { expect(ability).to be_able_to(:close, discussion) }
    end

    describe "Post management" do
      let(:post) { create(:post, user: other_user) }

      it { expect(ability).to be_able_to(:update, post) }
    end

    describe "Creating posts in closed discussions" do
      let(:closed_discussion) { create(:closed_discussion) }

      it "can post to closed discussions" do
        post = Post.new(exchange: closed_discussion)
        expect(ability).to be_able_to(:create, post)
      end
    end

    describe "Conversation participant management" do
      let(:conversation) { create(:conversation, poster: other_user) }
      let(:participant) { create(:user) }

      before { conversation.add_participant(participant) }

      it "can manage conversation relationships" do
        relationship = conversation.conversation_relationships.find_by(
          user: participant
        )
        expect(ability).to be_able_to(:manage, relationship)
      end
    end
  end

  describe "User admin abilities" do
    let(:user) { create(:user, :user_admin) }
    let(:other_user) { create(:user) }

    it "inherits authenticated abilities" do
      expect(ability).to be_able_to(:read, Discussion.new)
      expect(ability).to be_able_to(:create, Discussion.new)
    end

    describe "User management" do
      it { expect(ability).to be_able_to(:manage, User.new) }
      it { expect(ability).to be_able_to(:manage, other_user) }
    end

    describe "Invite management" do
      let(:invite) { create(:invite, user: other_user) }

      it { expect(ability).to be_able_to(:manage, Invite.new) }
      it { expect(ability).to be_able_to(:manage, invite) }
    end
  end

  describe "Admin abilities" do
    let(:user) { create(:user, :admin) }

    it "can manage everything" do
      expect(ability).to be_able_to(:manage, :all)
      expect(ability).to be_able_to(:manage, Discussion.new)
      expect(ability).to be_able_to(:manage, Conversation.new)
      expect(ability).to be_able_to(:manage, Post.new)
      expect(ability).to be_able_to(:manage, User.new)
      expect(ability).to be_able_to(:manage, Invite.new)
    end
  end
end
