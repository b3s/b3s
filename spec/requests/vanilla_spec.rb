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
      get "/vanilla/comments.php", params: { DiscussionID: discussion.id }
    end

    it { is_expected.to redirect_to(discussion_url(discussion)) }

    context "with page parameter" do
      before do
        get "/vanilla/comments.php",
            params: { DiscussionID: discussion.id, page: 2 }
      end

      it { is_expected.to redirect_to(discussion_url(discussion, page: 2)) }
    end
  end

  describe "GET /vanilla/account.php" do
    before { get "/vanilla/account.php", params: { u: 123 } }

    it { is_expected.to redirect_to(user_profile_url(id: 123)) }
  end
end
