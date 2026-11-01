# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PasswordResets" do
  let(:user) { create(:user) }
  let(:token) { user.generate_token_for(:password_reset) }
  let(:user_params) do
    { password: "new password", password_confirmation: "new password" }
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
        expect(flash[:notice]).to include("An email with further instructions has been sent")
      end

      it "sends an email to the user" do
        expect(last_email.to).to eq([user.email])
      end
    end

    context "when the email is enqueued" do
      it "does not put the token in the job arguments" do
        expect { post password_reset_path, params: { email: user.email } }
          .to have_enqueued_mail(Mailer, :password_reset).with(user)
      end
    end

    context "with a legacy password digest" do
      before do
        user.update(password_digest: Digest::SHA1.hexdigest("legacy"))
        perform_enqueued_jobs do
          post password_reset_path, params: { email: user.email }
        end
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
        expect(flash[:notice]).to include("An email with further instructions has been sent")
      end
    end
  end

  describe "POST /password_reset throttling" do
    around do |example|
      store = Rack::Attack.cache.store
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rack::Attack.cache.store = store
    end

    def request_reset(email, ip: "10.0.0.1")
      post password_reset_path, params: { email: },
                                headers: { "REMOTE_ADDR" => ip }
    end

    context "when one IP exceeds the limit" do
      before do
        5.times { |i| request_reset("none#{i}@example.com") }
      end

      it "does not send the email" do
        expect { request_reset(user.email) }
          .not_to have_enqueued_mail(Mailer, :password_reset)
      end

      it "redirects to login" do
        request_reset(user.email)
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        request_reset(user.email)
        expect(flash[:notice]).to include("An email with further instructions has been sent")
      end

      it "allows requests from other IPs" do
        expect { request_reset(user.email, ip: "10.0.0.2") }
          .to have_enqueued_mail(Mailer, :password_reset)
      end
    end

    context "when one email exceeds the limit across IPs" do
      before do
        5.times { |i| request_reset(user.email, ip: "10.0.1.#{i}") }
      end

      it "does not send the email" do
        expect { request_reset(user.email, ip: "10.0.2.1") }
          .not_to have_enqueued_mail(Mailer, :password_reset)
      end

      it "redirects to login" do
        request_reset(user.email, ip: "10.0.2.1")
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        request_reset(user.email, ip: "10.0.2.1")
        expect(flash[:notice]).to include("An email with further instructions has been sent")
      end
    end

    context "with case and whitespace variants of an email" do
      before do
        ["Target@Example.com", " target@example.com", "TARGET@EXAMPLE.COM ",
         "target @example.com", "tar get@example.com"].each_with_index do |email, i|
          request_reset(email, ip: "10.0.3.#{i}")
        end
      end

      it "counts them as the same email" do
        create(:user, email: "target@example.com")
        expect { request_reset("target@example.com", ip: "10.0.4.1") }
          .not_to have_enqueued_mail(Mailer, :password_reset)
      end
    end
  end

  describe "GET /password_reset" do
    it "sets the no-referrer policy" do
      get password_reset_path
      expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
    end

    context "with a valid token" do
      before { get password_reset_path, params: { token: } }

      it "redirects to the password reset page without the token" do
        expect(response).to redirect_to(password_reset_url)
      end

      it "renders the password reset form" do
        follow_redirect!
        expect(response).to have_http_status(:success)
      end

      it "shows which account is being reset" do
        follow_redirect!
        expect(response.body).to include(
          "Resetting the password for #{user.username}"
        )
      end
    end

    context "with a token for a legacy password digest" do
      before do
        user.update(password_digest: Digest::SHA1.hexdigest("legacy"))
        get password_reset_path, params: { token: }
      end

      it "redirects to the password reset page without the token" do
        expect(response).to redirect_to(password_reset_url)
      end
    end

    context "when decoding the token payload" do
      subject(:payload) { Base64.decode64(token.split("--").first) }

      it { is_expected.not_to include(user.email) }
    end

    context "when the email has changed since the token was issued" do
      before do
        token
        user.update(email: "changed@example.com")
        get password_reset_path, params: { token: }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "without a token" do
      before { get password_reset_path }

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("Not a valid URL")
      end
    end

    context "with an expired token" do
      before do
        token
        travel 25.hours
        get password_reset_path, params: { token: }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("Not a valid URL")
      end
    end

    context "with an invalid token" do
      before { get password_reset_path, params: { token: "456" } }

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("Not a valid URL")
      end
    end

    context "with a token that has already been used" do
      before do
        get password_reset_path, params: { token: }
        put password_reset_path, params: { user: user_params }
        delete session_path
        get password_reset_path, params: { token: }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("Not a valid URL")
      end
    end
  end

  describe "PUT /password_reset" do
    context "with valid data" do
      before do
        get password_reset_path, params: { token: }
        put password_reset_path, params: { user: user_params }
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("Your password has been changed")
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end

      it "logs the user in" do
        expect(session[:user_id]).to eq(user.id)
      end

      it "changes the password" do
        expect(user.reload.authenticate("new password")).to eq(user)
      end

      it "clears the token from the session" do
        expect(session[:password_reset_token]).to be_nil
      end

      it "sets the no-referrer policy" do
        expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      end
    end

    context "when signed in as another user" do
      let(:other_user) { create(:user) }

      before do
        login_as(other_user)
        get password_reset_path, params: { token: }
        put password_reset_path, params: { user: user_params }
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end

      it "logs in as the user whose password was reset" do
        expect(session[:user_id]).to eq(user.id)
      end

      it "changes the password" do
        expect(user.reload.authenticate("new password")).to eq(user)
      end
    end

    context "with a legacy password digest" do
      before do
        user.update(password_digest: Digest::SHA1.hexdigest("legacy"))
        get password_reset_path, params: { token: }
        put password_reset_path, params: { user: user_params }
      end

      it "changes the password" do
        expect(user.reload.authenticate("new password")).to eq(user)
      end
    end

    context "without valid data" do
      before do
        get password_reset_path, params: { token: }
        put password_reset_path,
            params: {
              user: {
                password: "new password",
                password_confirmation: "wrong password"
              }
            }
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "keeps the token in the session" do
        expect(session[:password_reset_token]).to eq(token)
      end
    end

    context "without a token in the session" do
      before { put password_reset_path, params: { token:, user: user_params } }

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("Not a valid URL")
      end
    end

    context "with an expired token" do
      before do
        get password_reset_path, params: { token: }
        travel 25.hours
        put password_reset_path, params: { user: user_params }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("Not a valid URL")
      end
    end

    context "when the password has changed since the token was stored" do
      before do
        get password_reset_path, params: { token: }
        user.update(password: "changed elsewhere",
                    password_confirmation: "changed elsewhere")
        put password_reset_path, params: { user: user_params }
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end

      it "does not change the password" do
        expect(user.reload.authenticate("new password")).to be(false)
      end

      it "clears the token from the session" do
        expect(session[:password_reset_token]).to be_nil
      end
    end
  end
end
