# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invites" do
  subject { response }

  let(:invite) { create(:invite) }
  let(:expired_invite) { create(:invite, expires_at: 2.days.ago) }
  let(:user) { create(:user, available_invites: 1) }

  before { create(:user) }

  # it_requires_login_for %w[index all new create destroy]
  # it_requires_user_admin_for "all"

  describe "GET /invites" do
    before do
      login_as(user)
      get invites_path
    end

    it { is_expected.to have_http_status(:success) }

    it_behaves_like "authentication is required"
  end

  describe "GET /invites/all" do
    let(:user) { create(:user, :user_admin) }

    before do
      login_as(user)
      get all_invites_path
    end

    it { is_expected.to have_http_status(:success) }

    it_behaves_like "authentication is required"
    it_behaves_like "user admin is required"
  end

  describe "GET /invites/accept/:id" do
    context "when invite is valid" do
      before { get accept_invite_path(invite.token) }

      it "stores the invite token in session" do
        expect(session[:invite_token]).to eq(invite.token)
      end

      it "redirects to signup page with token" do
        expect(response).to redirect_to(
          new_registration_by_token_url(token: invite.token)
        )
      end
    end

    context "when invite is expired" do
      before { get accept_invite_path(expired_invite.token) }

      it "sets the flash" do
        expect(flash[:notice]).to match(/Your invite has expired!/)
      end

      it "does not store the invite token" do
        expect(session[:invite_token]).to be_nil
      end

      it { is_expected.to redirect_to(new_session_url) }
    end

    context "when invite doesn't exist" do
      before { get accept_invite_path("invalid token") }

      it "sets the flash" do
        expect(flash[:notice]).to match(/That's not a valid invite!/)
      end

      it "does not store the invite token" do
        expect(session[:invite_token]).to be_nil
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end

  describe "GET /invites/new" do
    before do
      login_as(user)
      get new_invite_path
    end

    it { is_expected.to have_http_status(:success) }

    context "when user doesn't have invites" do
      let(:user) { create(:user, available_invites: 0) }

      it "sets the flash" do
        expect(flash[:notice]).to match(/You don't have any invites!/)
      end

      it { is_expected.to redirect_to(online_users_url) }
    end

    it_behaves_like "authentication is required"
  end

  describe "POST /invites" do
    let(:invite_params) do
      { email: "no-reply@example.com", message: "testing message" }
    end

    it_behaves_like "authentication is required" do
      before do
        login_as(user)
        perform_enqueued_jobs do
          post invites_path, params: { invite: invite_params }
        end
      end
    end

    context "with valid params" do
      before do
        login_as(user)
        perform_enqueued_jobs do
          post invites_path, params: { invite: invite_params }
        end
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(
          /Your invite has been sent to no-reply@example\.com/
        )
      end

      it "sends an email" do
        expect(last_email.to).to eq(["no-reply@example.com"])
      end

      it { is_expected.to redirect_to(invites_url) }
    end

    context "when email is invalid" do
      before do
        allow(Mailer).to receive(:invite).and_raise(
          Net::SMTPSyntaxError.new(nil), "mock error"
        )
        login_as(user)
        perform_enqueued_jobs do
          post invites_path,
               params: {
                 invite: {
                   email: "totally@wrong.com",
                   message: "testing message"
                 }
               }
        end
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(
          "There was a problem sending your invite to totally@wrong.com, " \
          "it has been cancelled."
        )
      end

      it { is_expected.to redirect_to(invites_url) }
    end

    context "with invalid params" do
      before do
        login_as(user)
        perform_enqueued_jobs do
          post invites_path,
               params: { invite: { email: "", message: "" } }
        end
      end

      it { is_expected.to have_http_status(:success) }
    end
  end

  describe "DELETE /invites/:id" do
    let(:invite_id) { invite.id }

    before do
      login_as(user)
      delete invite_path(invite_id)
    end

    it_behaves_like "authentication is required"

    context "when user owns the invite" do
      let(:user) { invite.user }

      it { is_expected.to redirect_to(invites_url) }
    end

    context "when user doesn't own the invite" do
      it { is_expected.to redirect_to(root_url) }
    end

    context "when invite doesn't exist" do
      let(:invite_id) { 1_231_115 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
