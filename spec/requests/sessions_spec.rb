# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions" do
  describe "GET /session/new" do
    before do
      # Ensure there's at least one user so detect_admin_signup doesn't
      # redirect.
      create(:user)
      get new_session_path
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "renders the login form" do
      expect(response.body).to include("Sign in")
    end
  end

  describe "POST /session" do
    let!(:user) { create(:user, password: "password123") }

    context "with valid credentials" do
      before do
        post session_path, params: {
          email: user.email,
          password: "password123"
        }
      end

      it "authenticates the user" do
        expect(controller.current_user).to eq(user)
      end

      it "redirects to discussions" do
        expect(response).to redirect_to(discussions_url)
      end
    end

    context "with invalid credentials" do
      before do
        post session_path, params: {
          email: user.email,
          password: "wrongpassword"
        }
      end

      it "does not authenticate the user" do
        expect(controller.current_user).to be_nil
      end

      it "sets the flash notice" do
        expect(flash[:notice]).to be_present
      end

      it "re-renders the login form" do
        expect(response.body).to include("Sign in")
      end
    end
  end

  describe "DELETE /session" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      delete session_path
    end

    it "logs out the user" do
      expect(controller.current_user).to be_nil
    end

    it "sets the flash" do
      expect(flash[:notice]).to match(/logged out/)
    end

    it "redirects to login" do
      expect(response).to redirect_to(new_session_url)
    end
  end
end
