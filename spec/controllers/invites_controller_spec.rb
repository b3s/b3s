# frozen_string_literal: true

require "rails_helper"

describe InvitesController do
  # Create the first admin user
  before { create(:user) }

  let(:invite) { create(:invite) }
  let(:expired_invite) { create(:invite, expires_at: 2.days.ago) }
  let(:user) { create(:user) }
  let(:user_with_invites) { create(:user, available_invites: 1) }

  it_requires_login_for %w[index all new create destroy]
  it_requires_user_admin_for "all"

  describe "#load_invite" do
    context "when invite exists" do
      before do
        login invite.user
        delete :destroy, params: { id: invite_id }
      end

      let(:invite_id) { invite.id }

      specify { expect(assigns(:invite)).to be_a(Invite) }
    end

    context "when invite doesn't exist" do
      let(:invite_id) { 1_231_115 }

      it "raises an error" do
        login invite.user
        expect do
          delete(:destroy, params: { id: invite_id })
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#verify_available_invites" do
    before do
      login(user)
      get :new
    end

    context "when user has invites" do
      let(:user) { create(:user, available_invites: 1) }

      it { is_expected.to respond_with(:success) }
      specify { expect(flash[:notice]).to be_nil }
    end

    context "when user is user admin" do
      let(:user) { create(:user, :user_admin) }

      it { is_expected.to respond_with(:success) }
      specify { expect(flash[:notice]).to be_nil }
    end

    context "when user doesn't have any invites" do
      let(:user) { create(:user, available_invites: 0) }

      specify { expect(flash[:notice]).to match(/You don't have any invites!/) }
      it { is_expected.to respond_with(:redirect) }
    end
  end

  describe "GET index" do
    let!(:invites) { [create(:invite, user:), create(:invite)] }

    before do
      login(user)
      get :index
    end

    it { is_expected.to respond_with(:success) }
    it { is_expected.to render_template(:index) }
    specify { expect(flash[:notice]).to be_nil }
    specify { expect(assigns(:invites)).to contain_exactly(invites.first) }
  end

  describe "GET all" do
    let(:user) { create(:user, :user_admin) }
    let!(:invites) { [create(:invite, user:), create(:invite)] }

    before do
      login(user)
      get :all
    end

    it { is_expected.to respond_with(:success) }
    it { is_expected.to render_template(:all) }
    specify { expect(assigns(:invites)).to match_array(invites) }
  end

  describe "GET accept" do
    before { get :accept, params: { id: token } }

    context "when invite is valid" do
      let(:token) { invite.token }

      specify { expect(flash[:notice]).to be_nil }
      specify { expect(session[:invite_token]).to eq(invite.token) }

      it "redirects to the signup page" do
        expect(response).to(
          redirect_to(new_user_by_token_url(token: invite.token))
        )
      end
    end

    context "when invite is expired" do
      let(:token) { expired_invite.token }

      specify { expect(flash[:notice]).to match(/Your invite has expired!/) }
      specify { expect(session[:invite_token]).to be_nil }

      it "redirects to the login page" do
        expect(response).to redirect_to(login_users_url)
      end
    end

    context "when invite doesn't exist" do
      let(:token) { "invalid token" }

      specify { expect(flash[:notice]).to match(/That's not a valid invite!/) }
      specify { expect(session[:invite_token]).to be_nil }

      it "redirects to the login page" do
        expect(response).to redirect_to(login_users_url)
      end
    end
  end

  describe "GET new" do
    before do
      login(user_with_invites)
      get :new
    end

    it { is_expected.to respond_with(:success) }
    it { is_expected.to render_template(:new) }
    specify { expect(assigns(:invite)).to be_a(Invite) }
  end

  describe "POST create" do
    before { login(user_with_invites) }

    context "with valid params" do
      before do
        perform_enqueued_jobs do
          post :create,
               params: {
                 invite: {
                   email: "no-reply@example.com",
                   message: "testing message"
                 }
               }
        end
      end

      specify { expect(assigns(:invite)).to be_a(Invite) }

      it "sets the flash" do
        expect(flash[:notice]).to match(
          /Your invite has been sent to no-reply@example\.com/
        )
      end

      specify { expect(last_email.to).to eq(["no-reply@example.com"]) }
      specify { expect(last_email.body.encoded).to match("testing message") }

      it { is_expected.to redirect_to(invites_url) }
    end

    context "when email is invalid" do
      before do
        allow(Mailer).to receive(:invite) do
          raise Net::SMTPSyntaxError.new(nil), "mock error"
        end
        post :create,
             params: {
               invite: {
                 email: "totally@wrong.com",
                 message: "testing message"
               }
             }
      end

      it "sets the flash" do
        expect(flash[:notice]).to match(
          "There was a problem sending your invite to totally@wrong.com, " \
          "it has been cancelled."
        )
      end

      it { is_expected.to redirect_to(invites_url) }

      it "does not send an email" do
        expect(last_email).to be_nil
      end

      it "does not create an invite" do
        expect(Invite.count).to eq(0)
      end
    end

    context "with invalid params" do
      before { post :create, params: { invite: { email: "", message: "" } } }

      specify { expect(assigns(:invite)).to be_a(Invite) }
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:new) }
    end
  end

  describe "DELETE destroy" do
    context "when user owns the invite" do
      before do
        login(invite.user) && delete(:destroy, params: { id: invite.id })
      end

      specify { expect(assigns(:invite)).to be_a(Invite) }
      specify { expect(assigns(:invite).destroyed?).to be(true) }

      it "redirects to the invites page" do
        expect(response).to redirect_to(invites_url)
      end
    end

    context "when user doesn't own the invite" do
      before { login(user) && delete(:destroy, params: { id: invite.id }) }

      specify { expect(assigns(:invite)).to be_a(Invite) }
      specify { expect(assigns(:invite).destroyed?).to be(false) }

      it "redirects to the discussions page" do
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
