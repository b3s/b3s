# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Profiles" do
  subject { response }

  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /users/profile/:user_id" do
    let(:profile_user) { create(:user) }

    before { get user_profile_path(profile_user.username) }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the user's username in the response" do
      expect(response.body).to include(profile_user.username)
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
