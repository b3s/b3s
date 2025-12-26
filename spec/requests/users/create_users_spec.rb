# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CreateUsers" do
  subject { response }

  let(:invite) { create(:invite) }

  before do
    configure signups_allowed: false
    create(:user) # Ensures the first user exists
  end

  describe "GET /users/new" do
    let(:params) { { token: invite.token } }

    before { get new_user_path, params: }

    it { is_expected.to have_http_status(:success) }

    context "without a valid invite token" do
      let(:params) { nil }

      it "sets the flash" do
        expect(flash[:notice]).to match("Signups are not allowed")
      end

      it "redirects to login" do
        expect(response).to redirect_to(login_users_url)
      end
    end

    context "with an expired invite token" do
      let(:invite) { create(:invite, :expired) }

      it "sets the flash" do
        expect(flash[:notice]).to match(/expired/)
      end

      it "redirects to login" do
        expect(response).to redirect_to(login_users_url)
      end
    end
  end

  describe "POST /users" do
    let(:user_params) do
      attributes_for(:user)
        .slice(:username, :email, :password, :password_confirmation, :realname)
    end
    let(:params) { { token: invite.token, user: user_params } }

    before { post users_path, params: }

    context "with a valid invite token" do
      it "redirects to user profile" do
        expect(response).to redirect_to(
          user_profile_url(id: user_params[:username])
        )
      end

      it "creates a new user" do
        expect(User.find_by(username: user_params[:username])).to be_present
      end
    end

    context "with an expired invite token" do
      let(:invite) { create(:invite, :expired) }

      it "sets the flash" do
        expect(flash[:notice]).to match(/expired/)
      end

      it "redirects to login" do
        expect(response).to redirect_to(login_users_url)
      end
    end

    context "when signups are not allowed without invite" do
      let(:params) { { user: user_params } }

      it "sets the flash" do
        expect(flash[:notice]).to match(/not allowed/)
      end

      it "redirects to login" do
        expect(response).to redirect_to(login_users_url)
      end
    end

    context "with invalid params" do
      let(:user_params) { { username: "", email: "", password: "" } }

      it { is_expected.to have_http_status(:success) }

      it "sets the flash" do
        expect(flash.now[:notice]).to match(/Could not create your account/)
      end

      it "re-renders the new form" do
        expect(response.body).to include("Username and password")
      end
    end
  end
end
