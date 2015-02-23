# encoding: utf-8

require "spec_helper"

describe SearchablePost, solr: true do
  let(:discussion) { create(:discussion, body: "testing discussion") }
  let(:conversation) { create(:conversation, body: "testing conversation") }
  let!(:post) { create(:post, body: "testing post") }
  let!(:trusted_post) { create(:trusted_post, body: "testing trusted post") }
  let!(:discussion_post) { discussion.posts.first }
  let!(:conversation_post) { conversation.posts.first }
  let(:user) { create(:user) }
  let(:trusted_user) { create(:trusted_user) }

  describe ".search_results" do
    before { Sunspot.commit }

    describe "searching all posts" do
      context "as nobody" do
        subject { Post.search_results("testing", user: nil, page: 1) }
        it { is_expected.to match_array([post, discussion_post]) }
      end

      context "as a regular user" do
        subject { Post.search_results("testing", user: user, page: 1) }
        it { is_expected.to match_array([post, discussion_post]) }
      end

      context "as a trusted user" do
        subject { Post.search_results("testing", user: trusted_user, page: 1) }
        it { is_expected.to match_array([post, discussion_post, trusted_post]) }
      end
    end

    describe "searching in a discussion" do
      context "as nobody" do
        subject do
          Post.search_results(
            "testing", user: nil, page: 1, exchange: discussion
          )
        end
        it { is_expected.to match_array([discussion_post]) }
      end

      context "as a regular user" do
        subject do
          Post.search_results(
            "testing", user: user, page: 1, exchange: discussion
          )
        end
        it { is_expected.to match_array([discussion_post]) }
      end
    end

    describe "searching in a conversation" do
      subject do
        Post.search_results(
          "testing", user: user, page: 1, exchange: conversation
        )
      end
      it { is_expected.to match_array([conversation_post]) }
    end
  end
end
