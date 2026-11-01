# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Profiles" do
  subject { response }

  let(:user) { create(:user) }

  before do
    create(:user) unless User.any?
    login_as(user)
  end

  describe "GET /users/profile/:user_id" do
    let(:profile_user) { create(:user) }

    before { get user_profile_path(profile_user.username) }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the user's username in the response" do
      expect(response.body).to include(profile_user.username)
    end

    context "when a user admin views an admin" do
      let(:user) { create(:user, :user_admin) }
      let(:profile_user) { create(:user, :admin) }

      it "does not link to the edit page" do
        expect(response.body)
          .not_to include(edit_user_profile_path(profile_user.username))
      end
    end

    context "when a user admin views a regular user" do
      let(:user) { create(:user, :user_admin) }

      it "links to the edit page" do
        expect(response.body)
          .to include(edit_user_profile_path(profile_user.username))
      end
    end
  end

  describe "GET /users/profile/:user_id/edit" do
    let(:target_user) { user || create(:user) }

    before { get edit_user_profile_path(target_user.username, page: "info") }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the edit form in the response" do
      expect(response.body).to include(user.username)
    end

    context "when user is a user_admin editing another user" do
      let(:user) { create(:user, :user_admin) }
      let(:other_user) { create(:user) }

      before { get edit_user_profile_path(other_user.username, page: "info") }

      it { is_expected.to have_http_status(:success) }
    end
  end

  describe "GET /users/profile/:user_id/edit?page=settings" do
    subject { response.body }

    let(:user) { create(:user, :user_admin) }

    before { get edit_user_profile_path(target_user.username, page: "settings") }

    context "when editing your own profile" do
      let(:target_user) { user }

      it { is_expected.to include("user[password_challenge]") }
    end

    context "when editing another user" do
      let(:target_user) { create(:user) }

      it { is_expected.not_to include("user[password]") }
      it { is_expected.to include("user[email]") }
    end
  end

  describe "PATCH /users/profile/:user_id" do
    let(:target_user) { user || create(:user) }
    let(:new_realname) { "Updated Name" }

    before do
      patch user_profile_path(target_user.username),
            params: { user: { realname: new_realname } }
    end

    it_behaves_like "authentication is required"

    it "updates the user" do
      user.reload
      expect(user.realname).to eq(new_realname)
    end

    it "redirects to edit page" do
      expect(response).to redirect_to(
        edit_user_profile_url(user.username, page: "info")
      )
    end
  end

  describe "PATCH /users/profile/:user_id as a user admin" do
    let(:user) { create(:user, :user_admin) }
    let(:params) { { user: { email: "changed@example.com" } } }

    before do
      perform_enqueued_jobs do
        patch user_profile_path(target_user.username), params:
      end
    end

    context "when editing an admin" do
      let(:target_user) { create(:user, :admin) }

      it { is_expected.to redirect_to(user_profile_url(target_user.username)) }

      it "does not update the admin" do
        expect(target_user.reload.email).not_to eq("changed@example.com")
      end
    end

    context "when changing a regular user's email" do
      let(:target_user) { create(:user, email: "old@example.com") }

      it "updates the email" do
        expect(target_user.reload.email).to eq("changed@example.com")
      end

      it "notifies the old address" do
        expect(last_email.to).to eq(["old@example.com"])
      end
    end

    context "when changing a regular user's password" do
      let(:target_user) { create(:user) }
      let(:params) do
        { user: { password: "new password", password_confirmation: "new password" } }
      end

      it "does not change the password" do
        expect(target_user.reload.authenticate("new password")).to be(false)
      end
    end
  end

  describe "PATCH /users/profile/:user_id as an admin" do
    let(:user) { create(:user, :admin) }
    let(:target_user) { create(:user, :admin) }

    before do
      patch user_profile_path(target_user.username),
            params: { user: { realname: "Changed", password: "new password",
                              password_confirmation: "new password" } }
    end

    it "updates the other admin" do
      expect(target_user.reload.realname).to eq("Changed")
    end

    it "does not change the other admin's password" do
      expect(target_user.reload.authenticate("new password")).to be(false)
    end
  end

  describe "PATCH /users/profile/:user_id changing your own credentials" do
    let(:current_password) { nil }
    let(:credentials) { { email: "changed@example.com" } }
    let(:params) do
      { page: "settings",
        user: credentials.merge(password_challenge: current_password).compact }
    end

    before do
      perform_enqueued_jobs do
        patch user_profile_path(user.username), params:
      end
    end

    context "without the current password" do
      it { is_expected.to have_http_status(:success) }

      it "does not update the email" do
        expect(user.reload.email).not_to eq("changed@example.com")
      end
    end

    context "with an empty current password" do
      let(:current_password) { "" }

      it "does not update the email" do
        expect(user.reload.email).not_to eq("changed@example.com")
      end
    end

    context "with the wrong current password" do
      let(:current_password) { "wrong password" }

      it "does not update the email" do
        expect(user.reload.email).not_to eq("changed@example.com")
      end

      it "shows a validation error" do
        expect(response.body)
          .to include('Current password<span class="error"> is invalid</span>')
      end
    end

    context "with the correct current password" do
      let(:user) { create(:user, email: "old@example.com") }
      let(:current_password) { user.password }

      it "updates the email" do
        expect(user.reload.email).to eq("changed@example.com")
      end

      it "notifies the old address" do
        expect(last_email.to).to eq(["old@example.com"])
      end
    end

    context "when changing the password without the current password" do
      let(:credentials) do
        { password: "new password", password_confirmation: "new password" }
      end

      it "does not change the password" do
        expect(user.reload.authenticate("new password")).to be(false)
      end
    end

    context "when changing the email and password without the current password" do
      let(:credentials) do
        { email: "changed@example.com", password: "new password",
          password_confirmation: "new password" }
      end

      it "does not change the password" do
        expect(user.reload.authenticate("new password")).to be(false)
      end

      it "does not update the email" do
        expect(user.reload.email).not_to eq("changed@example.com")
      end
    end

    context "when changing the password to whitespace without the current password" do
      let(:credentials) { { password: " " * 10, password_confirmation: " " * 10 } }

      it "does not change the password" do
        expect(user.reload.authenticate(user.password)).to eq(user)
      end
    end

    context "when changing the password to whitespace with the current password" do
      let(:current_password) { user.password }
      let(:credentials) { { password: " " * 10, password_confirmation: " " * 10 } }

      it "does not change the password" do
        expect(user.reload.authenticate(user.password)).to eq(user)
      end
    end

    context "when changing the password with the current password" do
      let(:current_password) { user.password }
      let(:credentials) do
        { password: "new password", password_confirmation: "new password" }
      end

      it "changes the password" do
        expect(user.reload.authenticate("new password")).to eq(user)
      end

      it "keeps the user logged in" do
        get edit_user_profile_path(user.username)
        expect(response).to have_http_status(:success)
      end
    end

    context "when changing other fields" do
      let(:credentials) { { realname: "Changed", email: user.email } }

      it "does not require the current password" do
        expect(user.reload.realname).to eq("Changed")
      end
    end
  end

  describe "POST /users/profile/:user_id/mute" do
    let(:target_user) { create(:user) }

    before { post mute_user_profile_path(target_user.username) }

    it_behaves_like "authentication is required"

    it "mutes the user" do
      expect(user.muted?(target_user)).to be(true)
    end

    it { is_expected.to redirect_to(user_profile_url(target_user.username)) }
  end

  describe "POST /users/profile/:user_id/unmute" do
    let(:target_user) { create(:user) }

    before do
      user&.mute!(target_user)
      post unmute_user_profile_path(target_user.username)
    end

    it_behaves_like "authentication is required"

    it "unmutes the user" do
      expect(user.muted?(target_user)).to be(false)
    end

    it { is_expected.to redirect_to(user_profile_url(target_user.username)) }
  end
end
