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

    context "when already logged in with an invite token in session" do
      before do
        login_as(create(:user))
        get accept_invites_path(token: create(:invite).token)
        get new_session_path
      end

      it "redirects to discussions" do
        expect(response).to redirect_to(discussions_url)
      end

      it "does not set the flash" do
        expect(flash[:notice]).to be_nil
      end
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

    context "with an existing session" do
      let(:mobile_user_agent) { "Mozilla/5.0 (Linux; Android 13) Mobile Safari/537.36" }
      let!(:previous_session_id) do
        get new_session_path(mobile_format: "desktop"),
            headers: { "HTTP_USER_AGENT" => mobile_user_agent }
        get password_reset_path(token: create(:user).generate_token_for(:password_reset))
        session.id.to_s
      end

      before do
        post session_path, params: { email: user.email, password: "password123" }
      end

      it "issues a new session id" do
        expect(session.id.to_s).not_to eq(previous_session_id)
      end

      it "drops the password reset token" do
        expect(session[:password_reset_token]).to be_nil
      end

      it "keeps the mobile format preference" do
        expect(session[:mobile_format]).to eq("desktop")
      end

      it "stores the user in the new session" do
        expect(session[:user_id]).to eq(user.id)
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

  describe "POST /session throttling", :rate_limit do
    let!(:user) { create(:user, password: "password123") }

    def sign_in(email, password: "wrong", ip: "10.0.0.1", path: session_path)
      post path, params: { email:, password: }, headers: { "REMOTE_ADDR" => ip }
    end

    def sign_in_with_json(email, password: "wrong", ip: "10.0.0.1")
      post session_path, params: { email:, password: }.to_json,
                         headers: { "REMOTE_ADDR" => ip,
                                    "CONTENT_TYPE" => "application/json" }
    end

    context "when one IP exceeds the limit" do
      before do
        5.times { |i| sign_in("none#{i}@example.com") }
        sign_in(user.email, password: "password123")
      end

      it "responds with too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end

      it "does not authenticate the user" do
        expect(session[:user_id]).to be_nil
      end
    end

    context "when another IP has exceeded the limit" do
      before do
        5.times { |i| sign_in("none#{i}@example.com") }
        sign_in(user.email, password: "password123", ip: "10.0.0.2")
      end

      it "authenticates the user" do
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "when one email exceeds the limit across IPs" do
      before do
        5.times { |i| sign_in(user.email, ip: "10.0.1.#{i}") }
        sign_in(user.email, password: "password123", ip: "10.0.2.1")
      end

      it "responds with too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end

      it "does not authenticate the user" do
        expect(session[:user_id]).to be_nil
      end
    end

    context "with case and whitespace variants of an email" do
      before do
        ["Target@Example.com", " target@example.com", "TARGET@EXAMPLE.COM ",
         "target @example.com", "tar get@example.com"].each_with_index do |email, i|
          sign_in(email, ip: "10.0.3.#{i}")
        end
        sign_in("target@example.com", ip: "10.0.4.1")
      end

      it "counts them as the same email" do
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "with a trailing slash" do
      before do
        6.times { |i| sign_in(user.email, ip: "10.0.1.#{i}", path: "/session/") }
      end

      it "responds with too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "with a format extension" do
      before do
        5.times { |i| sign_in(user.email, ip: "10.0.1.#{i}") }
        sign_in(user.email, ip: "10.0.2.1", path: "/session.json")
      end

      it "responds with too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "with a JSON body" do
      before do
        6.times { |i| sign_in_with_json(user.email, ip: "10.0.1.#{i}") }
      end

      it "responds with too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "with an array of emails from one IP" do
      before do
        6.times { |i| sign_in([user.email, "none#{i}@example.com"]) }
      end

      it "responds with too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe "POST /session with an array of emails" do
    let!(:user) { create(:user, password: "password123") }

    before do
      post session_path, params: { email: [user.email, "none@example.com"],
                                   password: "password123" }
    end

    it "does not authenticate the user" do
      expect(session[:user_id]).to be_nil
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
      expect(flash[:notice]).to include("logged out")
    end

    it "redirects to login" do
      expect(response).to redirect_to(new_session_url)
    end

    it "removes the user from the session" do
      expect(session.to_h.slice("user_id", "persistence_token").compact).to be_empty
    end
  end

  describe "DELETE /session with session state" do
    let(:user) { create(:user) }
    let(:mobile_user_agent) { "Mozilla/5.0 (Linux; Android 13) Mobile Safari/537.36" }
    let!(:previous_session_id) do
      login_as(user)
      get discussions_path(mobile_format: "desktop"),
          headers: { "HTTP_USER_AGENT" => mobile_user_agent }
      get accept_invites_path(token: create(:invite).token)
      session.id.to_s
    end

    before { delete session_path }

    it "issues a new session id" do
      expect(session.id.to_s).not_to eq(previous_session_id)
    end

    it "drops the invite token" do
      expect(session[:invite_token]).to be_nil
    end

    it "keeps the mobile format preference" do
      expect(session[:mobile_format]).to eq("desktop")
    end

    it "keeps the flash" do
      expect(flash[:notice]).to include("logged out")
    end
  end

  describe "DELETE /session/everywhere" do
    let(:user) { create(:user) }
    let!(:other_device) do
      open_session { |device| device.post(session_path, params: { email: user.email, password: user.password }) }
    end
    let!(:previous_token) { user.persistence_token }

    context "when logged in" do
      before do
        login_as(user)
        delete everywhere_session_path
      end

      it "rotates the persistence token" do
        expect(user.reload.persistence_token).not_to eq(previous_token)
      end

      it "logs out the current device" do
        expect(session[:user_id]).to be_nil
      end

      it "logs out other devices" do
        other_device.get edit_user_profile_path(user.username)
        expect(other_device.response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to eq("You have been logged out on all devices.")
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when not logged in" do
      before { delete everywhere_session_path }

      it "keeps other devices logged in" do
        expect(user.reload.persistence_token).to eq(previous_token)
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "without a CSRF token" do
      before do
        login_as(user)
        ActionController::Base.allow_forgery_protection = true
        delete everywhere_session_path
      end

      after { ActionController::Base.allow_forgery_protection = false }

      it "rejects the request" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "keeps other devices logged in" do
        expect(user.reload.persistence_token).to eq(previous_token)
      end
    end
  end
end
