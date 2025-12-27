# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Discussions" do
  subject { response }

  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /users/profile/:user_id/discussions" do
    let(:profile_user) { create(:user) }

    before { get user_profile_discussions_path(profile_user.username) }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }
  end

  describe "GET /users/profile/:user_id/participated" do
    let(:profile_user) { create(:user) }

    before do
      get participated_user_profile_discussions_path(profile_user.username)
    end

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }
  end
end
