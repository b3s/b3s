# frozen_string_literal: true

require "rails_helper"

RSpec.describe "UserLinks" do
  subject { response }

  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /user_links/all" do
    before { get all_user_links_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes user links heading in the response" do
      expect(response.body).to include("User links")
    end
  end

  describe "GET /user_links" do
    context "without type parameter" do
      before { get user_links_path }

      it "redirects to all user links" do
        expect(response).to redirect_to(all_user_links_url)
      end
    end

    context "with type parameter" do
      let!(:user_link) { create(:user_link, label: "GitHub") }

      before { get user_links_path, params: { type: "GitHub" } }

      it "includes the link type in the response" do
        expect(response.body).to include("GitHub")
      end

      it "includes users with the specified link type" do
        expect(response.body).to include(user_link.user.username)
      end
    end
  end
end
