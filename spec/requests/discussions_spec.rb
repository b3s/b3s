# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Discussions" do
  subject { response }

  let(:user) { create(:user) }
  let(:discussion) { create(:discussion) }

  before do
    # Create first user so subsequent users aren't auto-admin
    create(:user) unless User.any?
    login_as(user)
  end

  describe "GET /discussions" do
    let!(:discussion) { create(:discussion) }

    before { get discussions_path }

    it { is_expected.to have_http_status(:success) }

    it "includes the discussion in the response" do
      expect(response.body).to include(discussion.title)
    end

    it_behaves_like "authentication is required"
  end

  describe "GET /discussions/:id" do
    let(:discussion) { create(:discussion) }

    before { get discussion_path(discussion) }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the discussion in the response" do
      expect(response.body).to include(discussion.title)
    end

    context "when discussion does not exist" do
      let(:discussion) { 999_999 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end

  describe "GET /discussions/new" do
    before { get new_discussion_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the discussion form in the response" do
      expect(response.body).to include("New discussion")
    end
  end

  describe "POST /discussions" do
    let(:params) { { discussion: { title: "Test", body: "Test" } } }

    before { post(discussions_path, params:) }

    it_behaves_like "authentication is required"

    it "redirects to the discussion" do
      expect(response).to redirect_to(discussion_url(Discussion.last))
    end

    it "creates a discussion" do
      expect(Discussion.last).to(
        have_attributes(title: "Test", poster: user)
      )
    end

    context "with invalid params" do
      let(:params) { { discussion: { title: "", body: "" } } }

      it { is_expected.to have_http_status(:success) }

      it "sets the flash" do
        expect(flash.now[:notice]).to eq(I18n.t("exchange.invalid"))
      end

      it "re-renders the form" do
        expect(response.body).to include("New discussion")
      end
    end
  end

  describe "GET /discussions/:id/edit" do
    before { get edit_discussion_path(discussion) }

    it_behaves_like "authentication is required"

    context "when user is the discussion owner" do
      let(:user) { discussion.poster }

      it { is_expected.to have_http_status(:success) }

      it "includes the discussion form in the response" do
        expect(response.body).to include(discussion.title)
      end
    end

    context "when user is a moderator" do
      let(:user) { create(:user, :moderator) }

      it { is_expected.to have_http_status(:success) }

      it "includes the discussion form in the response" do
        expect(response.body).to include(discussion.title)
      end
    end

    context "when user is not authorized" do
      it { is_expected.to have_http_status(:forbidden) }
    end
  end

  describe "PUT /discussions/:id" do
    let(:params) do
      { discussion: { title: "Updated", body: "Updated body" } }
    end

    before { put discussion_path(discussion), params: }

    it_behaves_like "authentication is required"

    context "when user is the discussion owner" do
      let(:user) { discussion.poster }

      it "redirects to the discussion" do
        expect(response).to redirect_to(
          discussion_url(discussion.reload)
        )
      end

      it "sets a flash notice" do
        expect(flash[:notice]).to eq(I18n.t("changes_saved"))
      end

      it "updates the discussion" do
        expect(discussion.reload.title).to eq("Updated")
      end
    end

    context "when user is a moderator" do
      let(:user) { create(:user, :moderator) }

      it "redirects to the discussion" do
        expect(response).to redirect_to(
          discussion_url(discussion.reload)
        )
      end

      it "updates the discussion" do
        expect(discussion.reload.title).to eq("Updated")
      end
    end

    context "when user is not authorized" do
      it { is_expected.to have_http_status(:forbidden) }
    end

    context "with invalid params" do
      let(:user) { discussion.poster }
      let(:params) { { discussion: { title: "" } } }

      it { is_expected.to have_http_status(:success) }

      it "sets the flash" do
        expect(flash.now[:notice]).to eq(I18n.t("exchange.invalid"))
      end

      it "re-renders the form" do
        expect(response.body).to include("Edit")
      end
    end

    context "when discussion does not exist" do
      let(:discussion) { 999_999 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end

  describe "PUT /discussions/:id closing and reopening" do
    let(:params) { { discussion: { closed: "1" } } }

    before { put discussion_path(discussion), params: }

    context "when user is the discussion owner" do
      let(:user) { discussion.poster }

      it "closes the discussion" do
        expect(discussion.reload.closed?).to be(true)
      end

      it "sets the closer" do
        expect(discussion.reload.closer).to eq(user)
      end
    end

    context "when user is a moderator" do
      let(:user) { create(:user, :moderator) }

      it "closes the discussion" do
        expect(discussion.reload.closed?).to be(true)
      end
    end

    context "when user is not authorized" do
      it { is_expected.to have_http_status(:forbidden) }
    end

    context "when reopening a closed discussion" do
      let(:user) { discussion.poster }
      let(:discussion) { create(:closed_discussion) }
      let(:params) { { discussion: { closed: "0" } } }

      it "reopens the discussion" do
        expect(discussion.reload.closed?).to be(false)
      end

      it "clears the closer" do
        expect(discussion.reload.closer).to be_nil
      end
    end
  end

  describe "PUT /discussions/:id with sticky flag" do
    let(:params) { { discussion: { sticky: "1" } } }

    before { put discussion_path(discussion), params: }

    context "when user is a moderator" do
      let(:user) { create(:user, :moderator) }

      it "sets the sticky flag" do
        expect(discussion.reload.sticky?).to be(true)
      end
    end

    context "when user is not a moderator" do
      let(:user) { discussion.poster }

      it "does not set the sticky flag" do
        expect(discussion.reload.sticky?).to be(false)
      end
    end
  end

  describe "GET /discussions/popular" do
    before do
      create(:discussion)
      get popular_discussions_path
    end

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes discussions in the response" do
      expect(response.body).to include("Popular")
    end

    context "with days parameter" do
      before { get popular_discussions_path, params: { days: 30 } }

      it { is_expected.to have_http_status(:success) }
    end

    context "with days parameter exceeding max" do
      before { get popular_discussions_path, params: { days: 365 } }

      it { is_expected.to have_http_status(:success) }
    end
  end

  describe "GET /discussions/search" do
    before { get search_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "renders the search page" do
      expect(response.body).to include("Search")
    end

    context "with query parameter" do
      let!(:discussion) do
        create(:discussion, title: "Findme Special Topic")
      end

      before do
        get search_path, params: { q: "Findme" }
      end

      it "renders search results page" do
        expect(response.body).to include(discussion.title)
      end
    end
  end

  describe "GET /discussions/favorites" do
    before { get favorites_discussions_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes favorites heading in the response" do
      expect(response.body).to include("Favorites")
    end

    context "with favorited discussions" do
      let!(:favorited_discussion) { create(:discussion) }

      before do
        create(:discussion_relationship,
               user:, discussion: favorited_discussion, favorite: true)
        get favorites_discussions_path
      end

      it "includes the favorited discussion" do
        expect(response.body).to include(favorited_discussion.title)
      end
    end
  end

  describe "GET /discussions/following" do
    before { get following_discussions_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes following heading in the response" do
      expect(response.body).to include("Following")
    end

    context "with followed discussions" do
      let!(:followed_discussion) { create(:discussion) }

      before do
        create(:discussion_relationship,
               user:, discussion: followed_discussion, following: true)
        get following_discussions_path
      end

      it "includes the followed discussion" do
        expect(response.body).to include(followed_discussion.title)
      end
    end
  end

  describe "GET /discussions/hidden" do
    before { get hidden_discussions_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes hidden heading in the response" do
      expect(response.body).to include("Hidden")
    end

    context "with hidden discussions" do
      let!(:hidden_discussion) { create(:discussion) }

      before do
        create(:discussion_relationship,
               user:, discussion: hidden_discussion, hidden: true)
        get hidden_discussions_path
      end

      it "includes the hidden discussion" do
        expect(response.body).to include(hidden_discussion.title)
      end
    end
  end

  describe "GET /discussions/:id when id is not a discussion" do
    let(:conversation) { create(:conversation) }

    before { get discussion_path(conversation) }

    it "redirects to the conversation" do
      expect(response).to redirect_to(conversation_url(conversation))
    end
  end

  describe "GET /discussions/:id/search_posts" do
    let(:query) { nil }
    let!(:matching_post) do
      create(:post, exchange: discussion, body: "findme unique content")
    end

    before { get search_posts_discussion_path(discussion, q: query) }

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

    context "when discussion does not exist" do
      before { get search_posts_discussion_path(999_999, q: "test") }

      it { is_expected.to have_http_status(:not_found) }
    end
  end

  describe "GET /discussions/:id/mark_as_read" do
    let(:headers) { { "X-Requested-With": "XMLHttpRequest" } }

    context "with discussion" do
      before { get mark_as_read_discussion_path(discussion), headers: }

      it_behaves_like "authentication is required"

      it { is_expected.to have_http_status(:success) }

      it "returns OK response" do
        expect(response.body).to include("OK")
      end
    end

    context "when discussion does not exist" do
      before { get mark_as_read_discussion_path(999_999), headers: }

      it { is_expected.to have_http_status(:not_found) }
    end
  end

  describe "GET /discussions/:id/follow" do
    before { get follow_discussion_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    it "redirects to the discussion" do
      expect(response).to redirect_to(discussion_url(discussion, page: 2))
    end

    it "sets following to true" do
      relationship = user.discussion_relationships
                         .find_by(discussion:)
      expect(relationship.following?).to be(true)
    end
  end

  describe "GET /discussions/:id/unfollow" do
    before { get unfollow_discussion_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    it "redirects to discussions index" do
      expect(response).to redirect_to(discussions_url)
    end

    it "sets following to false" do
      relationship = user.discussion_relationships
                         .find_by(discussion:)
      expect(relationship.following?).to be(false)
    end
  end

  describe "GET /discussions/:id/favorite" do
    before { get favorite_discussion_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    it "redirects to the discussion" do
      expect(response).to redirect_to(discussion_url(discussion, page: 2))
    end

    it "sets favorite to true" do
      relationship = user.discussion_relationships
                         .find_by(discussion:)
      expect(relationship.favorite?).to be(true)
    end
  end

  describe "GET /discussions/:id/unfavorite" do
    before { get unfavorite_discussion_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    it "redirects to discussions index" do
      expect(response).to redirect_to(discussions_url)
    end

    it "sets favorite to false" do
      relationship = user.discussion_relationships
                         .find_by(discussion:)
      expect(relationship.favorite?).to be(false)
    end
  end

  describe "GET /discussions/:id/hide" do
    before { get hide_discussion_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    it "redirects to discussions index" do
      expect(response).to redirect_to(discussions_url)
    end

    it "sets hidden to true" do
      relationship = user.discussion_relationships
                         .find_by(discussion:)
      expect(relationship.hidden?).to be(true)
    end
  end

  describe "GET /discussions/:id/unhide" do
    before { get unhide_discussion_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    it "redirects to the discussion" do
      expect(response).to redirect_to(discussion_url(discussion, page: 2))
    end

    it "sets hidden to false" do
      relationship = user.discussion_relationships
                         .find_by(discussion:)
      expect(relationship.hidden?).to be(false)
    end
  end
end
