# frozen_string_literal: true

require "rails_helper"

describe ExchangesHelper do
  let(:user) { create(:user) }
  let(:exchange) { create(:discussion, title: "Test") }

  let(:read_exchange) do
    discussion = create(:discussion, title: "Test")
    user.mark_exchange_viewed(discussion, discussion.posts.first, 1)
    discussion
  end

  let(:post) { exchange.posts.first }

  before do
    viewed_tracker = ViewedTracker.new(user)
    allow(viewed_tracker).to receive(:exchanges).and_return([exchange])
    allow(helper).to receive(:viewed_tracker)
      .and_return(viewed_tracker)
  end

  describe "#exchange_classes" do
    subject(:results) { helper.exchange_classes(collection, exchange) }

    let(:collection) { [exchange] }

    it "results in an array" do
      expect(results).to(
        contain_exactly("odd", "by_user#{exchange.poster.id}",
                        "discussion", "discussion#{exchange.id}", "new_posts")
      )
    end

    context "when exchange is read" do
      let(:exchange) { read_exchange }

      it { is_expected.not_to include("new_posts") }
    end

    context "when exchange has flags" do
      let(:exchange) do
        create(
          :discussion, nsfw: true, sticky: true, closed: true
        )
      end

      it { is_expected.to include("sticky") }
      it { is_expected.to include("closed") }
      it { is_expected.to include("nsfw") }
    end

    context "when exchange is even numbered" do
      let(:collection) { [create(:discussion), exchange] }

      it { is_expected.to include("even") }
      it { is_expected.not_to include("odd") }
    end
  end

  describe "new_posts_count" do
    subject { helper.new_posts_count(exchange) }

    context "when discussion is unread" do
      it { is_expected.to eq(1) }
    end

    context "when discussion is read" do
      let(:exchange) { read_exchange }

      it { is_expected.to eq(0) }
    end
  end

  describe "new_posts?" do
    subject { helper.new_posts?(exchange) }

    context "when discussion is unread" do
      it { is_expected.to be(true) }
    end

    context "when discussion is read" do
      let(:exchange) { read_exchange }

      it { is_expected.to be(false) }
    end
  end

  describe "#last_viewed_page_path" do
    subject { helper.last_viewed_page_path(exchange) }

    context "when discussion is unread" do
      it { is_expected.to eq("/discussions/#{exchange.id}-Test") }
    end

    context "when discussion is read" do
      let(:exchange) { read_exchange }
      let(:path) { "/discussions/#{exchange.id}-Test#post-#{post.id}" }

      it { is_expected.to eq(path) }
    end
  end
end
