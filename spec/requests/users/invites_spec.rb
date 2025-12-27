# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Invites" do
  subject { response }

  before do
    # Create first user so subsequent users aren't auto-admin
    create(:user) unless User.any?
    login_as(user)
  end

  describe "POST /users/:user_id/invites" do
    let(:target_user) { create(:user) }

    before do
      post user_invites_path(target_user.username)
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

      it "redirects to user profile" do
        expect(response).to redirect_to(
          user_profile_url(target_user.username)
        )
      end
    end

    context "when user is not a user_admin" do
      let(:user) { create(:user) }

      it "does not increase the user's available invites" do
        expect(target_user.available_invites).to eq(0)
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "DELETE /users/:user_id/invites" do
    let(:target_user) { create(:user, available_invites: 1) }

    before do
      delete user_invites_path(target_user.username)
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

      it "redirects to user profile" do
        expect(response).to redirect_to(
          user_profile_url(target_user.username)
        )
      end
    end

    context "when user is not a user_admin" do
      let(:user) { create(:user) }

      it "does not change the user's available invites" do
        expect(target_user.available_invites).to eq(1)
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
