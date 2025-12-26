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
end
