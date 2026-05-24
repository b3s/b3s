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
end
