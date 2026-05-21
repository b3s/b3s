# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile views" do
  subject { response }

  let(:user) { create(:user) }
  let(:mobile_user_agent) do
    "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 " \
      "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
  end

  before do
    create(:user) unless User.any?
    configure(default_mobile_theme: "b3s")
    login_as(user)
  end

  def get_mobile(path, **)
    get(path, **, headers: { "HTTP_USER_AGENT" => mobile_user_agent })
  end

  describe "discussion thread" do
    let(:discussion) { create(:discussion) }
    let!(:thread_post) { create(:post, exchange: discussion) }

    before { get_mobile discussion_path(discussion) }

    it { is_expected.to have_http_status(:success) }

    it "renders the mobile layout" do
      expect(response.body).to include("Regular site")
    end

    it "renders the posts" do
      expect(response.body).to include(thread_post.body)
    end
  end

  describe "conversation thread" do
    let(:conversation) do
      create(:conversation).tap { |c| c.add_participant(user) }
    end
    let!(:thread_post) { create(:post, exchange: conversation) }

    before { get_mobile conversation_path(conversation) }

    it { is_expected.to have_http_status(:success) }

    it "renders the posts" do
      expect(response.body).to include(thread_post.body)
    end
  end

  describe "posts search" do
    let!(:found_post) { create(:post, body: "findme on mobile search") }

    before { get_mobile search_posts_path, params: { q: "findme" } }

    it { is_expected.to have_http_status(:success) }

    it "renders the matching post" do
      expect(response.body).to include(found_post.body)
    end

    it "renders pagination" do
      expect(response.body).to include('class="pagination"')
    end
  end

  describe "in-discussion post search" do
    let(:discussion) { create(:discussion) }
    let!(:found_post) do
      create(:post, exchange: discussion, body: "findme within discussion")
    end

    before do
      get_mobile(search_discussion_posts_path(discussion), params: { q: "findme" })
    end

    it { is_expected.to have_http_status(:success) }

    it "renders the matching post" do
      expect(response.body).to include(found_post.body)
    end

    it "renders pagination" do
      expect(response.body).to include('class="pagination"')
    end
  end
end
