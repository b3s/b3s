# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registrations" do
  subject { response }

  let(:invite) { create(:invite) }
  let(:user_params) do
    attributes_for(:user).slice(
      :username, :email, :password, :password_confirmation, :realname
    )
  end

  before do
    configure signups_allowed: false
    create(:user) # Ensures the first user exists
  end

  def accept_invite(invite)
    get accept_invites_path(token: invite.token)
  end

  describe "GET /registrations/new" do
    context "with an invite token in session" do
      before do
        accept_invite(invite)
        get new_registration_path
      end

      it { is_expected.to have_http_status(:success) }

      it "prefills the invited email" do
        expect(response.body).to include(invite.email)
      end

      it "does not put the token in the page" do
        expect(response.body).not_to include(invite.token)
      end
    end

    context "without an invite token" do
      before { get new_registration_path }

      it "sets the flash" do
        expect(flash[:notice]).to match("Signups are not allowed")
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "with an invite token in the query string" do
      before { get new_registration_path, params: { token: invite.token } }

      it "ignores it" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when the invite has expired since it was accepted" do
      before do
        accept_invite(invite)
        invite.update(expires_at: 2.days.ago)
        get new_registration_path
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("expired")
      end

      it "clears the invite token" do
        expect(session[:invite_token]).to be_nil
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when signups are allowed" do
      before do
        configure signups_allowed: true
        get new_registration_path
      end

      it { is_expected.to have_http_status(:success) }
    end
  end

  describe "POST /registrations" do
    let(:params) { { user: user_params } }

    context "with an invite token in session" do
      before do
        accept_invite(invite)
        post registrations_path, params:
      end

      it "redirects to user profile" do
        expect(response).to redirect_to(
          user_profile_url(id: user_params[:username])
        )
      end

      it "creates a new user" do
        expect(User.find_by(username: user_params[:username])).to(
          be_present
        )
      end

      it "clears the invite token" do
        expect(session[:invite_token]).to be_nil
      end

      it "uses up the invite" do
        expect(Invite.exists?(invite.id)).to be(false)
      end
    end

    context "when the invite has expired since it was accepted" do
      before do
        accept_invite(invite)
        invite.update(expires_at: 2.days.ago)
        post registrations_path, params:
      end

      it "sets the flash" do
        expect(flash[:notice]).to include("expired")
      end

      it "does not create a user" do
        expect(User.find_by(username: user_params[:username])).to be_nil
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when signups are not allowed without invite" do
      before { post registrations_path, params: }

      it "sets the flash" do
        expect(flash[:notice]).to include("not allowed")
      end

      it "redirects to login" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "with an invite token in the params" do
      before do
        post registrations_path,
             params: { token: invite.token, user: user_params }
      end

      it "ignores it" do
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "with invalid params" do
      let(:user_params) { { username: "", email: "", password: "" } }

      before do
        accept_invite(invite)
        post registrations_path, params:
      end

      it { is_expected.to have_http_status(:success) }

      it "sets the flash" do
        expect(flash.now[:notice]).to include("Could not create your account")
      end

      it "re-renders the new form" do
        expect(response.body).to include("Username and password")
      end

      it "keeps the invite token" do
        expect(session[:invite_token]).to eq(invite.token)
      end
    end
  end

  describe "welcome email" do
    let(:params) { { user: user_params } }

    it "only passes the user to the mailer" do
      accept_invite(invite)
      expect { post registrations_path, params: }
        .to have_enqueued_mail(Mailer, :new_user).with(an_instance_of(User))
    end

    it "links to the login page on the default host" do
      host! "elsewhere.example.org"
      accept_invite(invite)
      perform_enqueued_jobs { post registrations_path, params: }
      expect(last_email.body.encoded).to include("http://example.com/session/new")
    end
  end
end
