# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Posts" do
  subject { response }

  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /users/profile/:user_id/posts" do
    let(:profile_user) { create(:user) }

    before { get user_profile_posts_path(profile_user.username) }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }
  end
end
