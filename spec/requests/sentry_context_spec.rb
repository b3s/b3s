# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sentry context" do
  let(:user) { create(:user) }

  before do
    create(:user)
    login_as(user)
    allow(Sentry).to receive(:set_extras)
  end

  def have_set_params(params)
    have_received(:set_extras).with(params: hash_including(params))
  end

  describe "POST /discussions/:discussion_id/posts" do
    before do
      post discussion_posts_path(create(:discussion), email: "user@example.com"),
           params: { q: "search",
                     post: { body: "Secret post", format: "html" } }
    end

    it "filters the post body" do
      expect(Sentry).to have_set_params(
        "post" => { "body" => "[FILTERED]", "format" => "html" }
      )
    end

    it "applies the Rails parameter filter" do
      expect(Sentry).to have_set_params("email" => "[FILTERED]")
    end

    it "keeps unrelated params" do
      expect(Sentry).to have_set_params("q" => "search")
    end
  end

  describe "POST /conversations" do
    before do
      post conversations_path,
           params: { recipient_id: create(:user).id,
                     conversation: { title: "Private title",
                                     body: "Private body" } }
    end

    it "filters the conversation title and body" do
      expect(Sentry).to have_set_params(
        "conversation" => { "title" => "[FILTERED]", "body" => "[FILTERED]" }
      )
    end
  end

  describe "POST /discussions" do
    before do
      post discussions_path,
           params: { discussion: { title: "Public title",
                                   body: "Discussion body" } }
    end

    it "keeps the discussion title" do
      expect(Sentry).to have_set_params(
        "discussion" => { "title" => "Public title", "body" => "[FILTERED]" }
      )
    end
  end
end
