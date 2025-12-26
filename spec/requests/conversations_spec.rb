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
    before do
      get conversation_path(conversation)
    end

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

    before do
      post conversations_path,
           params: {
             recipient_id: recipient.id,
             conversation: { title: "Test", body: "Test" }
           }
    end

    it_behaves_like "authentication is required"

    it "redirects to the conversation" do
      expect(response).to redirect_to(conversation_url(Conversation.last))
    end

    it "adds the recipient to the conversation" do
      expect(Conversation.last.participants).to include(recipient)
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
end
