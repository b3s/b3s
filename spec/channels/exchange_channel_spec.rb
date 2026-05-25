# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExchangeChannel do
  let(:user) { create(:user) }
  let(:exchange) { create(:discussion) }

  before { stub_connection(current_user: user) }

  context "when the exchange is viewable" do
    before { subscribe(id: exchange.id) }

    it "streams broadcasts for the exchange" do
      expect(subscription.streams).to include(described_class.broadcasting_for(exchange))
    end
  end

  context "when the exchange is a conversation the user does not participate in" do
    let(:exchange) { create(:conversation) }

    before { subscribe(id: exchange.id) }

    it "rejects the subscription" do
      expect(subscription).to be_rejected
    end
  end

  context "when the exchange does not exist" do
    before { subscribe(id: 999_999) }

    it "rejects the subscription" do
      expect(subscription).to be_rejected
    end
  end

  describe "#viewed" do
    let!(:post) { create(:post, exchange:) }

    before { subscribe(id: exchange.id) }

    it "marks the exchange viewed up to the given index" do
      expect do
        perform :viewed, post_id: post.id, index: 2
      end.to change { ExchangeView.find_by(user:, exchange:)&.post_index }.to(2)
    end

    context "when the exchange is a conversation" do
      let(:exchange) { create(:conversation, poster: user) }

      it "marks the conversation read" do
        relationship = user.conversation_relationships.find_by(conversation: exchange)
        relationship.update(new_posts: true)
        expect do
          perform :viewed, post_id: post.id, index: 2
        end.to change { relationship.reload.new_posts }.from(true).to(false)
      end
    end

    context "when the post does not belong to the exchange" do
      let(:other_post) { create(:post) }

      it "does not create a view" do
        expect do
          perform :viewed, post_id: other_post.id, index: 2
        end.not_to change(ExchangeView, :count)
      end
    end
  end
end
