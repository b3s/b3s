# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PasswordResets" do
  let(:user) { create(:user) }
  let(:expires_at) { 24.hours.from_now }

  let(:token) do
    Rails.application.message_verifier(:password_reset)
         .generate(user.id, expires_at:)
  end

  describe "GET /password_reset/new" do
    before { get new_password_reset_path }

    it "returns success" do
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /password_reset" do
    context "with an existing user" do
      before do
        perform_enqueued_jobs do
          post password_reset_path, params: { email: user.email }
        end
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(
          /An email with further instructions has been sent/
        )
      end

      it "sends an email to the user" do
        expect(last_email.to).to eq([user.email])
      end
    end

    context "with a non-existant user" do
      before do
        post password_reset_path, params: { email: "none@example.com" }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(
          /An email with further instructions has been sent/
        )
      end
    end
  end

  describe "GET /password_reset" do
    context "with a valid token" do
      before do
        get password_reset_path, params: { token: }
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end
    end

    context "without a valid token" do
      before { get password_reset_path }

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(/Not a valid URL/)
      end
    end

    context "with an expired token" do
      let(:expires_at) { 2.days.ago }

      before { get password_reset_path, params: { token: } }

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(/Not a valid URL/)
      end
    end

    context "with an invalid token" do
      before { get password_reset_path, params: { token: "456" } }

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(/Not a valid URL/)
      end
    end
  end

  describe "PUT /password_reset" do
    context "with valid data" do
      before do
        put password_reset_path,
            params: {
              token:,
              user: { password: "new password",
                      password_confirmation: "new password" }
            }
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(/Your password has been changed/)
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end

      it "logs the user in" do
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "without valid data" do
      before do
        put password_reset_path,
            params: {
              token:,
              user: {
                password: "new password",
                password_confirmation: "wrong password"
              }
            }
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end
    end

    context "without a valid token" do
      before do
        put password_reset_path,
            params: {
              user: { password: "new password",
                      password_confirmation: "new password" }
            }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(/Not a valid URL/)
      end
    end

    context "with an expired token" do
      let(:expires_at) { 2.days.ago }

      before do
        put password_reset_path,
            params: {
              token:,
              user: { password: "new password",
                      password_confirmation: "new password" }
            }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(/Not a valid URL/)
      end
    end
  end
end
