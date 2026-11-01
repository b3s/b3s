# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Profiles log out everywhere" do
  subject { response.body }

  let(:user) { create(:user) }
  let(:target_user) { user }
  let(:page) { "settings" }

  before do
    login_as(user)
    get edit_user_profile_path(target_user.username, page:)
  end

  context "when editing your own settings" do
    it { is_expected.to include(everywhere_session_path) }
  end

  context "when editing another page" do
    let(:page) { "info" }

    it { is_expected.not_to include(everywhere_session_path) }
  end

  context "when a user admin edits another user's settings" do
    let(:user) { create(:user, :user_admin) }
    let(:target_user) { create(:user) }

    it { is_expected.not_to include(everywhere_session_path) }
  end
end
