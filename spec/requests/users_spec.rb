# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users" do
  subject { response }

  let(:user) { create(:user) }

  before do
    # Create first user so subsequent users aren't auto-admin
    create(:user) unless User.any?
    login_as(user)
  end

  describe "GET /users" do
    let!(:user) { create(:user) }

    before { get users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the user in the response" do
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /users.json" do
    before { get users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end

  describe "GET /users/deactivated" do
    before { get deactivated_users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }
  end

  describe "GET /users/deactivated.json" do
    before { get deactivated_users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end

  describe "GET /users/profile/:id" do
    let(:profile_user) { create(:user) }

    before { get user_profile_path(profile_user.username) }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the user's username in the response" do
      expect(response.body).to include(profile_user.username)
    end

    context "when user does not exist" do
      let(:profile_user) { double(username: "nonexistent") }

      it { is_expected.to have_http_status(:not_found) }
    end
  end

  describe "GET /users/profile/:id/edit" do
    before do
      target = user || create(:user)
      get edit_user_page_path(target.username, page: "info")
    end

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the edit form in the response" do
      expect(response.body).to include(user.username)
    end

    context "when user is a user_admin editing another user" do
      let(:user) { create(:user, :user_admin) }
      let(:other_user) { create(:user) }

      before { get edit_user_page_path(other_user.username, page: "info") }

      it { is_expected.to have_http_status(:success) }

      it "includes the edit form in the response" do
        expect(response.body).to include(other_user.username)
      end
    end

    context "when user tries to edit another user without privileges" do
      let(:other_user) { create(:user) }

      before { get edit_user_page_path(other_user.username, page: "info") }

      it { is_expected.to redirect_to(user_profile_url(other_user.username)) }

      it "sets the flash" do
        expect(flash[:notice]).to eq("You don't have permission to do that!")
      end
    end
  end

  describe "POST /users/profile/:id/grant_invite" do
    let(:target_user) { create(:user) }

    before do
      post grant_invite_user_path(target_user.username)
      target_user.reload
    end

    it_behaves_like "authentication is required"

    context "when user is a user_admin" do
      let(:user) { create(:user, :user_admin) }

      it "increases the user's available invites" do
        expect(target_user.available_invites).to eq(1)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match("has been granted one invite")
      end

      it { is_expected.to redirect_to(user_profile_url(target_user.username)) }
    end

    context "when user is not a user_admin" do
      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end

      it "does not grant an invite" do
        expect(target_user.available_invites).to eq(0)
      end
    end
  end

  describe "POST /users/profile/:id/revoke_invites" do
    let(:target_user) { create(:user, available_invites: 1) }

    before do
      post revoke_invites_user_path(target_user.username)
      target_user.reload
    end

    it_behaves_like "authentication is required"

    context "when user is a user_admin" do
      let(:user) { create(:user, :user_admin) }

      it "sets user's available invites to zero" do
        expect(target_user.available_invites).to eq(0)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match("has been revoked of all invites")
      end

      it { is_expected.to redirect_to(user_profile_url(target_user.username)) }
    end

    context "when user is not a user_admin" do
      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end

      it "does not revoke invites" do
        expect(target_user.available_invites).to eq(1)
      end
    end
  end

  describe "PUT /users/:id" do
    let(:params) { { user: { realname: "Test" } } }
    let(:target_user) { create(:user) }

    before do
      put user_path(target_user.id), params:
    end

    it_behaves_like "authentication is required"

    shared_examples "user is updated" do
      it "updates the user's realname" do
        expect(target_user.reload.realname).to eq("Test")
      end

      it "sets the flash" do
        expect(flash[:notice]).to eq(I18n.t("flash.changes_saved"))
      end

      it "redirects back to the edit page" do
        expect(response).to redirect_to(
          edit_user_page_url(target_user.username, page: "info")
        )
      end
    end

    context "when updating own profile" do
      let(:target_user) { user }

      it_behaves_like "user is updated"
    end

    context "when user_admin updates another user" do
      let(:user) { create(:user, :user_admin) }
      let(:target_user) { create(:user) }

      it_behaves_like "user is updated"
    end

    context "when going on hiatus" do
      let(:target_user) { user }
      let(:params) { { user: { hiatus_until: (Time.now.utc + 2.days) } } }

      it "sets the user as temporarily banned" do
        expect(target_user.reload.temporary_banned?).to be(true)
      end
    end

    context "when user tries to update another user without privileges" do
      let(:target_user) { create(:user) }

      it "redirects to the user profile" do
        expect(response).to redirect_to(user_profile_url(target_user.username))
      end

      it "sets the flash" do
        expect(flash[:notice]).to eq("You don't have permission to do that!")
      end

      it "does not update the user" do
        expect(target_user.reload.realname).not_to eq("Test")
      end
    end

    context "when user_admin bans a user" do
      let(:user) { create(:user, :user_admin) }
      let(:target_user) { create(:user) }
      let(:params) { { user: { status: :banned } } }

      it "bans the target user" do
        expect(target_user.reload.banned?).to be(true)
      end
    end

    context "when regular user tries to set admin fields" do
      let(:params) { { user: { status: :banned, moderator: true } } }

      it "does not change the status" do
        expect(user.reload.banned?).to be(false)
      end

      it "does not grant moderator privileges" do
        expect(user.reload.moderator?).to be(false)
      end
    end

    context "with invalid params" do
      let(:target_user) { user }
      let(:params) { { user: { email: "invalid" } } }

      it { is_expected.to have_http_status(:success) }

      it "sets the flash" do
        expect(flash.now[:notice]).to eq(I18n.t("flash.invalid_record"))
      end

      it "re-renders the edit form" do
        expect(response.body).to include("Edit")
      end
    end

    context "when user does not exist" do
      let(:target_user) { double(id: 9999) }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
