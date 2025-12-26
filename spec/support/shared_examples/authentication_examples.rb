# frozen_string_literal: true

RSpec.shared_examples "authentication is required" do
  context "when not authenticated" do
    let(:user) { nil }

    before do
      allow(B3S).to receive(:public_browsing?).and_return(false)
    end

    it { is_expected.to redirect_to(login_users_url) }
  end
end

RSpec.shared_examples "user admin is required" do
  context "when user is not a user admin" do
    let(:user) { create(:user, user_admin: false) }

    it { is_expected.to redirect_to(root_url) }
  end
end

RSpec.shared_examples "admin is required" do
  context "when user is not an admin" do
    let(:user) { create(:user, admin: false) }

    it { is_expected.to redirect_to(root_url) }
  end
end
