# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Posts" do
  subject { response }

  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /posts/search" do
    context "without query" do
      before { get search_posts_path }

      it_behaves_like "authentication is required"

      it { is_expected.to have_http_status(:success) }

      it "renders the search page" do
        expect(response.body).to include("Searching posts")
      end
    end

    context "with search query" do
      let!(:existing_post) { create(:post, body: "findme unique content") }

      before { get search_posts_path, params: { q: "findme" } }

      it "renders search results page" do
        expect(response.body).to include(existing_post.body)
      end
    end
  end
end
