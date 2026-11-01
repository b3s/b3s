# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Vanilla" do
  subject { response }

  describe "GET /vanilla" do
    before { get "/vanilla" }

    it { is_expected.to redirect_to(paged_discussions_url(page: 1)) }
  end

  describe "GET /vanilla with page parameter" do
    before { get "/vanilla", params: { page: 3 } }

    it { is_expected.to redirect_to(paged_discussions_url(page: 3)) }
  end

  describe "GET /vanilla/index.php" do
    before { get "/vanilla/index.php" }

    it { is_expected.to redirect_to(paged_discussions_url(page: 1)) }
  end

  describe "GET /vanilla/comments.php" do
    let(:discussion) { create(:discussion) }

    before do
      configure public_browsing: true
      get "/vanilla/comments.php", params: { DiscussionID: discussion.id }
    end

    it { is_expected.to redirect_to(discussion_url(discussion)) }

    context "when public browsing is disabled" do
      before do
        configure public_browsing: false
        get "/vanilla/comments.php", params: { DiscussionID: discussion.id }
      end

      it { is_expected.to have_http_status(:not_found) }

      it "does not redirect" do
        expect(response.location.to_s).not_to include(discussion.to_param)
      end
    end

    context "with page parameter" do
      before do
        get "/vanilla/comments.php",
            params: { DiscussionID: discussion.id, page: 2 }
      end

      it { is_expected.to redirect_to(discussion_url(discussion, page: 2)) }
    end
  end

  describe "GET /vanilla/comments.php with a conversation" do
    let(:conversation) { create(:conversation, title: "Secret plans") }

    before do
      create(:user) unless User.any?
      login_as(user)
      get "/vanilla/comments.php", params: { DiscussionID: conversation.id }
    end

    context "when user is a participant" do
      let(:user) { conversation.poster }

      it { is_expected.to redirect_to(conversation_url(conversation)) }
    end

    context "when user is not a participant" do
      let(:user) { create(:user) }

      it { is_expected.to have_http_status(:not_found) }

      it "does not redirect" do
        expect(response.location.to_s).not_to include(conversation.to_param)
      end
    end

    context "when not authenticated" do
      let(:user) { nil }

      it { is_expected.to have_http_status(:not_found) }

      it "does not redirect" do
        expect(response.location.to_s).not_to include(conversation.to_param)
      end
    end
  end

  describe "GET /vanilla/account.php" do
    before { get "/vanilla/account.php", params: { u: 123 } }

    it { is_expected.to redirect_to(user_profile_url(id: 123)) }
  end
end
