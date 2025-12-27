# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversations" do
  subject { response }

  let(:participant) { create(:user) }
  let(:user) { participant }

  let(:conversation) do
    create(:conversation).tap do |c|
      c.add_participant(participant)
      c.add_participant(user) if user && user != participant
    end
  end

  before do
    create(:user)
    login_as(user)
  end

  describe "GET /conversations" do
    before { get conversations_path }

    it { is_expected.to have_http_status(:success) }

    it_behaves_like "authentication is required"
  end

  describe "GET /conversations/:id" do
    before { get conversation_path(conversation) }

    it { is_expected.to have_http_status(:success) }

    it_behaves_like "authentication is required"
  end

  describe "DELETE /conversations/:id/remove_participant" do
    before do
      delete remove_participant_conversation_path(
        conversation,
        username: participant.username
      )
    end

    it_behaves_like "authentication is required"

    context "when removing self" do
      it "sets the flash" do
        expect(flash[:notice]).to match(
          /You have been removed from the conversation/
        )
      end

      it { is_expected.to redirect_to(conversations_url) }

      it "removes the user from the conversation" do
        expect(conversation.reload.participants.to_a)
          .not_to(include(participant))
      end
    end

    context "when removing someone else" do
      let(:user) { create(:user, :moderator) }

      it "sets the flash" do
        expect(flash[:notice]).to eq(
          "#{participant.username} has been removed from the conversation"
        )
      end

      it { is_expected.to redirect_to(conversation_url(conversation)) }

      it "removes the user from the conversation" do
        expect(conversation.reload.participants.to_a)
          .not_to(include(participant))
      end
    end

    context "when removing someone else without privileges" do
      let(:user) { create(:user) }

      it "sets the flash" do
        expect(flash[:error]).to eq("You can't do that!")
      end

      it { is_expected.to redirect_to(conversation_url(conversation)) }

      it "does not remove the user from the conversation" do
        expect(conversation.reload.participants.to_a)
          .to(include(participant))
      end
    end
  end

  describe "GET /conversations/new" do
    let(:recipient) { create(:user) }

    before do
      get new_conversation_path(type: "conversation",
                                username: recipient.username)
    end

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }
  end

  describe "POST /conversations" do
    let(:recipient) { create(:user) }
    let(:conversation_params) { { title: "Test", body: "Test" } }

    before do
      post conversations_path,
           params: { recipient_id: recipient.id,
                     conversation: conversation_params }
    end

    it_behaves_like "authentication is required"

    it "redirects to the conversation" do
      expect(response).to redirect_to(conversation_url(Conversation.last))
    end

    it "adds the recipient to the conversation" do
      expect(Conversation.last.participants).to include(recipient)
    end

    context "with invalid params" do
      let(:conversation_params) { { title: "", body: "" } }

      it { is_expected.to have_http_status(:success) }

      it "sets the flash" do
        expect(flash.now[:notice]).to eq(I18n.t("conversation.invalid"))
      end

      it "re-renders the form" do
        expect(response.body).to include("New")
      end

      it "does not create a conversation" do
        expect(Conversation.count).to eq(0)
      end
    end

    context "with missing title" do
      let(:conversation_params) { { title: "", body: "Test body" } }

      it { is_expected.to have_http_status(:success) }

      it "does not create a conversation" do
        expect(Conversation.count).to eq(0)
      end
    end
  end

  describe "GET /conversations/:id/mute" do
    before { get mute_conversation_path(conversation, page: 2) }

    it_behaves_like "authentication is required"

    it "mutes the conversation" do
      expect(user.muted_conversation?(conversation)).to be(true)
    end

    it { is_expected.to redirect_to(conversation_url(conversation, page: 2)) }
  end

  describe "GET /conversations/:id/unmute" do
    before do
      conversation
      user&.conversation_relationships
          &.each { |cr| cr.update(notifications: false) }
      get unmute_conversation_path(conversation, page: 2)
    end

    it_behaves_like "authentication is required"

    it "unmutes the conversation" do
      expect(user.muted_conversation?(conversation)).to be(false)
    end

    it { is_expected.to redirect_to(conversation_url(conversation, page: 2)) }
  end

  describe "POST /conversations/:id/invite_participant" do
    let(:users) { [create(:user)] }

    before do
      post invite_participant_conversation_path(
        conversation,
        username: users.map(&:username).join(",")
      )
    end

    it_behaves_like "authentication is required"

    it "redirects to the conversation" do
      expect(response).to redirect_to(conversation_url(conversation))
    end

    it "adds the user to the conversation" do
      expect(conversation.reload.participants).to include(users.first)
    end

    context "with multiple users (CSV)" do
      let(:users) { create_list(:user, 2) }

      it "adds the users to the conversation" do
        expect(conversation.reload.participants).to include(*users)
      end
    end

    context "with non-existent username" do
      let(:users) { [double(username: "nonexistent")] }

      it "redirects without error" do
        expect(response).to redirect_to(conversation_url(conversation))
      end
    end

    context "with empty username" do
      let(:users) { [] }

      it "redirects without error" do
        expect(response).to redirect_to(conversation_url(conversation))
      end
    end

    context "with already existing participant" do
      let(:users) { [participant] }

      it "redirects without error" do
        expect(response).to redirect_to(conversation_url(conversation))
      end

      it "does not duplicate participant" do
        expect(
          conversation.reload.participants.where(id: participant.id).count
        ).to eq(1)
      end
    end
  end

  describe "GET /conversations/:id/search_posts" do
    let(:query) { nil }
    let!(:matching_post) do
      create(:post, exchange: conversation, user: participant,
                    body: "findme unique content")
    end

    before { get search_posts_conversation_path(conversation, q: query) }

    it_behaves_like "authentication is required"

    context "with search query" do
      let(:query) { "findme" }

      it { is_expected.to have_http_status(:success) }

      it "includes matching posts in the response" do
        expect(response.body).to include(matching_post.body)
      end
    end

    context "with empty query" do
      let(:query) { "" }

      it { is_expected.to have_http_status(:success) }
    end

    context "when conversation does not exist" do
      before { get search_posts_conversation_path(999_999, q: "test") }

      it { is_expected.to have_http_status(:not_found) }
    end
  end

  describe "GET /conversations/:id/mark_as_read" do
    let(:headers) { { "X-Requested-With": "XMLHttpRequest" } }

    context "with conversation" do
      before { get mark_as_read_conversation_path(conversation), headers: }

      it_behaves_like "authentication is required"

      it { is_expected.to have_http_status(:success) }

      it "returns OK response" do
        expect(response.body).to include("OK")
      end
    end

    context "when conversation does not exist" do
      before { get mark_as_read_conversation_path(999_999), headers: }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
