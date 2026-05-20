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

  describe "GET /posts/:id" do
    let(:exchange) { create(:discussion) }
    let(:post_record) { create(:post, exchange:) }
    let(:post_id) { post_record.id }

    before { get post_path(post_id) }

    it_behaves_like "authentication is required"

    it "redirects to the post's permalink" do
      expect(response).to redirect_to(
        discussion_url(exchange, page: post_record.page,
                                 anchor: "post-#{post_record.id}")
      )
    end

    context "when the post does not exist" do
      let(:post_id) { 999_999 }

      it { is_expected.to have_http_status(:not_found) }
    end

    context "when the post is in a conversation the user can see" do
      let(:exchange) { create(:conversation) }
      let(:post_record) { create(:post, exchange:, user: exchange.poster) }
      let(:user) { exchange.poster }

      it "redirects to the conversation permalink" do
        expect(response).to redirect_to(
          conversation_url(exchange, page: post_record.page,
                                     anchor: "post-#{post_record.id}")
        )
      end
    end

    context "when the post is in a conversation the user cannot see" do
      let(:exchange) { create(:conversation) }
      let(:post_record) { create(:post, exchange:, user: exchange.poster) }

      it "responds with not found" do
        expect(response).to have_http_status(:not_found)
      end

      it "does not reveal the conversation" do
        expect(response).not_to be_redirect
      end
    end
  end
end
