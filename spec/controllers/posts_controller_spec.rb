# frozen_string_literal: true

require "rails_helper"

describe PostsController do
  # Create the first admin user
  before { create(:user) }

  let(:user)          { create(:user) }
  let(:discussion)    { create(:discussion) }
  let(:existing_post) { create(:post, exchange: discussion, user:) }

  describe "Valid POST" do
    before { login(user) }

    let(:post_params) { { body: "foo", format: "html" } }

    context "with HTML format" do
      before do
        post :create,
             params: { discussion_id: discussion.id, post: post_params }
      end

      specify { expect(assigns(:post)).to be_valid }

      it "redirects back to the discussion" do
        expect(response).to(
          redirect_to(discussion_url(discussion,
                                     page: 1,
                                     anchor: "post-#{assigns(:post).id}"))
        )
      end
    end

    context "with JSON format" do
      before do
        post(
          :create,
          params: {
            discussion_id: discussion.id,
            post: post_params
          },
          format: :json
        )
      end

      specify { expect(assigns(:post)).to be_valid }
      it { is_expected.to respond_with(:created) }

      it "returns the expected JSON response" do
        expect(response.parsed_body).to eq(JSON.parse(assigns(:post).to_json))
      end
    end
  end

  describe "Invalid POST" do
    before { login(user) }

    let(:post_params) { { body: "", format: "html" } }

    context "with HTML format" do
      before do
        post :create,
             params: { discussion_id: discussion.id, post: post_params }
      end

      specify { expect(assigns(:post)).not_to be_valid }
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:new) }
    end

    context "with JSON format" do
      before do
        post(
          :create,
          params: {
            discussion_id: discussion.id,
            post: post_params
          },
          format: :json
        )
      end

      specify { expect(assigns(:post)).not_to be_valid }
      it { is_expected.to respond_with(:unprocessable_content) }
    end
  end

  describe "Valid PUT" do
    before { login(user) }

    let(:post_params) { { body: "foo", format: "html" } }

    context "with HTML format" do
      before do
        put(
          :update,
          params: {
            discussion_id: existing_post.exchange_id,
            id: existing_post.id,
            post: post_params
          }
        )
      end

      specify { expect(assigns(:post)).to be_valid }

      it "redirects back to the discussion" do
        expect(response).to(
          redirect_to(discussion_url(discussion,
                                     page: 1,
                                     anchor: "post-#{assigns(:post).id}"))
        )
      end
    end

    context "with JSON format" do
      before do
        put(
          :update,
          params: {
            discussion_id: existing_post.exchange_id,
            id: existing_post.id,
            post: post_params
          },
          format: :json
        )
      end

      specify { expect(assigns(:post)).to be_valid }
      it { is_expected.to respond_with(:success) }
    end
  end

  describe "Invalid PUT" do
    before { login(user) }

    let(:post_params) { { body: "", format: "wrong_format" } }

    context "with HTML format" do
      before do
        put(
          :update,
          params: {
            discussion_id: existing_post.exchange_id,
            id: existing_post.id,
            post: post_params
          }
        )
      end

      specify { expect(assigns(:post)).not_to be_valid }
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:edit) }
    end

    context "with JSON format" do
      before do
        put(
          :update,
          params: {
            discussion_id: existing_post.exchange_id,
            id: existing_post.id,
            post: post_params
          },
          format: :json
        )
      end

      specify { expect(assigns(:post)).not_to be_valid }
      it { is_expected.to respond_with(:unprocessable_content) }
    end
  end
end
