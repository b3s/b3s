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

  shared_examples "an invite link" do
    context "when invite is valid" do
      let(:token) { invite.token }

      it "stores the invite token in session" do
        expect(session[:invite_token]).to eq(invite.token)
      end

      it "redirects to signup page without the token" do
        expect(response).to redirect_to(new_registration_url)
      end

      it "sets the referrer policy" do
        expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      end
    end

    context "when invite is expired" do
      let(:token) { expired_invite.token }

      it "sets the flash" do
        expect(flash[:notice]).to include("Your invite has expired!")
      end

      it "does not store the invite token" do
        expect(session[:invite_token]).to be_nil
      end

      it "destroys the invite" do
        expect(Invite.exists?(expired_invite.id)).to be(false)
      end

      it { is_expected.to redirect_to(new_session_url) }
    end

    context "when invite doesn't exist" do
      let(:token) { "invalid token" }

      it "sets the flash" do
        expect(flash[:notice]).to include("That's not a valid invite!")
      end

      it "does not store the invite token" do
        expect(session[:invite_token]).to be_nil
      end

      it "sets the referrer policy" do
        expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end

  describe "GET /invites/accept" do
    before { get accept_invites_path(token:) }

    it_behaves_like "an invite link"

    context "without a token" do
      let(:token) { nil }

      it "sets the flash" do
        expect(flash[:notice]).to include("That's not a valid invite!")
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
        expect(flash[:notice]).to include("You don't have any invites!")
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
        expect(flash[:notice]).to include("Your invite has been sent to no-reply@example.com")
      end

      it "sends an email" do
        expect(last_email.to).to eq(["no-reply@example.com"])
      end

      it { is_expected.to redirect_to(invites_url) }
    end

    context "when the request comes from another host" do
      before do
        host! "elsewhere.example.org"
        login_as(user)
        perform_enqueued_jobs do
          post invites_path, params: { invite: invite_params }
        end
      end

      it "links to the default host in the email" do
        expect(last_email.body.encoded).to include(
          "http://example.com/invites/accept?token=#{Invite.last.token}"
        )
      end
    end

    context "when the email is enqueued" do
      before { login_as(user) }

      it "only passes the invite to the mailer" do
        expect { post invites_path, params: { invite: invite_params } }
          .to have_enqueued_mail(Mailer, :invite).with(an_instance_of(Invite))
      end
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
