# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackfillPostPositionsJob do
  let(:exchange) { create(:discussion) }

  before do
    create_list(:post, 3, exchange:)
    null_positions(exchange)
  end

  describe "#perform" do
    it "assigns sequential positions ordered by id" do
      described_class.new.perform(exchange.id)
      expect(exchange.posts.order(:id).pluck(:position)).to eq([1, 2, 3, 4])
    end

    it "only touches NULL-position rows when re-run" do
      described_class.new.perform(exchange.id)
      first_pass = exchange.posts.order(:id).pluck(:position)
      described_class.new.perform(exchange.id)
      expect(exchange.posts.order(:id).pluck(:position)).to eq(first_pass)
    end

    it "leaves other exchanges untouched" do
      other = create(:discussion)
      null_positions(other)
      described_class.new.perform(exchange.id)
      expect(other.posts.pluck(:position)).to all(be_nil)
    end
  end

  def null_positions(exchange)
    Post.connection.exec_update(
      "UPDATE posts SET position = NULL WHERE exchange_id = $1",
      "test-setup", [exchange.id]
    )
  end
end
