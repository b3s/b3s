# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ConversationParticipants" do
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

  describe "DELETE /conversations/:id/participants/:username" do
    before do
      delete conversation_participant_path(
        conversation,
        participant.username
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

  describe "POST /conversations/:id/participants" do
    let(:users) { [create(:user)] }

    before do
      post conversation_participants_path(
        conversation,
        usernames: users.map(&:username).join(",")
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
end
