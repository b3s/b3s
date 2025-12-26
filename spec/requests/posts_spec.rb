# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Posts" do
  subject { response }

  let(:user) { create(:user) }
  let(:exchange) { create(:discussion) }

  before do
    # Create first user so subsequent users aren't auto-admin
    create(:user) unless User.any?
    login_as(user)
  end

  describe "POST /discussions/:discussion_id/posts" do
    let(:format) { :html }
    let(:post_params) { { body: "foo", format: "html" } }

    before do
      post discussion_posts_path(exchange, format:),
           params: { post: post_params }
    end

    it_behaves_like "authentication is required"

    it "redirects to the discussion with new post anchor" do
      expect(response).to redirect_to(
        discussion_url(exchange, page: 1, anchor: "post-#{Post.last.id}")
      )
    end

    it "creates a post" do
      expect(Post.last).to(
        have_attributes(body: "foo", format: "html", user:, exchange:)
      )
    end

    context "when format is JSON" do
      let(:format) { :json }

      it { is_expected.to have_http_status(:created) }

      it "returns the post as JSON" do
        expect(response.parsed_body).to(
          include("id" => Post.last.id, "body" => "foo", "user_id" => user.id,
                  "exchange_id" => exchange.id)
        )
      end
    end

    context "with invalid params and JSON format" do
      let(:format) { :json }
      let(:post_params) { { body: "", format: "html" } }

      it { is_expected.to have_http_status(:unprocessable_content) }

      it "returns the invalid post as JSON" do
        expect(response.parsed_body).to include("body" => "", "id" => nil)
      end
    end

    context "when discussion is closed" do
      let(:exchange) { create(:closed_discussion) }

      it "redirects to the discussion" do
        expect(response).to redirect_to(
          discussion_url(exchange, page: exchange.last_page)
        )
      end

      it "sets a flash notice" do
        expect(flash[:notice]).to eq(I18n.t("exchange.closed"))
      end

      it "does not create a post" do
        expect(Post.where(exchange:).count).to eq(1)
      end
    end

    context "when user is a moderator and discussion is closed" do
      let(:user) { create(:user, :moderator) }
      let(:exchange) { create(:closed_discussion) }

      it "allows the post" do
        expect(response).to redirect_to(
          discussion_url(exchange, page: 1, anchor: "post-#{Post.last.id}")
        )
      end

      it "creates a post with the correct attributes" do
        expect(Post.last).to(
          have_attributes(body: "foo", format: "html", user:, exchange:)
        )
      end
    end
  end

  describe "POST /conversations/:conversation_id/posts" do
    let(:exchange) { create(:conversation) }
    let(:participant) { exchange.poster }
    let(:post_params) { { body: "foo", format: "html" } }

    before do
      post conversation_posts_path(exchange),
           params: { post: post_params }
    end

    context "when user is a participant" do
      let(:user) { participant }

      it "redirects to the post" do
        expect(response).to redirect_to(
          conversation_url(exchange, page: 1, anchor: "post-#{Post.last.id}")
        )
      end

      it "creates a post with the correct attributes" do
        expect(Post.last).to(
          have_attributes(body: "foo", format: "html", user:, exchange:)
        )
      end
    end

    context "when user is not a participant" do
      it "redirects to the conversation" do
        expect(response).to redirect_to(
          conversation_url(exchange, page: exchange.last_page)
        )
      end

      it "sets a flash notice" do
        expect(flash[:notice]).to eq(I18n.t("exchange.closed"))
      end

      it "does not create a post" do
        expect(Post.where(exchange:, user:).count).to eq(0)
      end
    end
  end

  describe "PUT /discussions/:discussion_id/posts/:id" do
    let(:format) { :html }
    let(:post_params) { { body: "foo", format: "html" } }
    let(:existing_post) { create(:post, exchange:) }
    let(:user) { existing_post.user }

    before do
      put discussion_post_path(exchange, existing_post || 1, format:),
          params: { post: post_params }
    end

    it_behaves_like "authentication is required"

    it "redirects to the discussion with post anchor" do
      expect(response).to redirect_to(
        discussion_url(exchange, page: 1, anchor: "post-#{existing_post.id}")
      )
    end

    it "updates the post body" do
      expect(existing_post.reload.body).to eq("foo")
    end

    it "sets the edited_at timestamp" do
      expect(existing_post.reload.edited_at).to be_present
    end

    context "when format is JSON" do
      let(:format) { :json }

      it { is_expected.to have_http_status(:success) }

      it "returns the updated post as JSON" do
        expect(response.parsed_body).to(
          include("id" => existing_post.id, "body" => "foo",
                  "user_id" => existing_post.user_id,
                  "exchange_id" => exchange.id)
        )
      end
    end

    context "with invalid params" do
      let(:format) { :json }
      let(:post_params) { { body: "", format: "wrong_format" } }

      it { is_expected.to have_http_status(:unprocessable_content) }

      it "returns the invalid post as JSON" do
        expect(response.parsed_body).to include(
          "id" => existing_post.id,
          "body" => ""
        )
      end
    end

    context "when user does not own the post" do
      let(:user) { create(:user) }

      it "redirects to the discussion" do
        expect(response).to redirect_to(
          discussion_url(exchange, page: exchange.last_page)
        )
      end

      it "sets a flash notice" do
        expect(flash[:notice]).to eq(I18n.t("post.not_editable"))
      end

      it "does not update the post" do
        expect(existing_post.reload.body).not_to eq("foo")
      end
    end

    context "when user is a moderator editing another user's post" do
      let(:user) { create(:user, :moderator) }

      it "allows the edit" do
        expect(response).to redirect_to(
          discussion_url(exchange, page: 1, anchor: "post-#{existing_post.id}")
        )
      end

      it "updates the post body" do
        expect(existing_post.reload.body).to eq("foo")
      end

      it "sets the edited_at timestamp" do
        expect(existing_post.reload.edited_at).to be_present
      end
    end

    context "when post does not exist" do
      let(:existing_post) { 12_345 }
      let(:user) { create(:user) }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
