# frozen_string_literal: true

require "rails_helper"

describe Paginatable::PositionKeyed do
  let(:exchange) { create(:discussion) }

  before do
    Post.per_page = 5
    9.times { create(:post, exchange:) }
  end

  after { Post.per_page = 50 }

  describe ".page" do
    it "selects posts via WHERE position BETWEEN" do
      expect(exchange.posts.page(2).to_sql)
        .to include(%("posts"."position" BETWEEN 6 AND 10))
    end

    it "does not generate an OFFSET clause" do
      expect(exchange.posts.page(2).to_sql).not_to match(/OFFSET/i)
    end

    it "returns the page's worth of posts" do
      page2 = exchange.posts.page(2).load
      expect(page2.map(&:position)).to eq([6, 7, 8, 9, 10])
    end

    it "includes context rows on pages after the first" do
      page2 = exchange.posts.page(2, context: 2).load
      expect(page2.map(&:position)).to eq([4, 5, 6, 7, 8, 9, 10])
    end

    it "ignores context on page 1" do
      page1 = exchange.posts.page(1, context: 2).load
      expect(page1.map(&:position)).to eq([1, 2, 3, 4, 5])
    end

    it "clamps page < 1 to page 1" do
      page0 = exchange.posts.page(0).load
      expect(page0.map(&:position)).to eq([1, 2, 3, 4, 5])
    end

    it "returns no rows past the last page" do
      expect(exchange.posts.page(99).load).to be_empty
    end
  end

  describe ".current_page" do
    specify { expect(exchange.posts.page(1).current_page).to eq(1) }
    specify { expect(exchange.posts.page(2).current_page).to eq(2) }
  end

  describe ".total_pages" do
    it "uses the seeded total_count" do
      scope = exchange.posts.page(1, total_count: 100)
      expect(scope.total_pages).to eq(20)
    end
  end

  describe ".pagination_offset" do
    it "reports the row count skipped before the page" do
      expect(exchange.posts.page(2).pagination_offset).to eq(5)
    end

    it "subtracts context from the offset on pages after the first" do
      expect(exchange.posts.page(2, context: 2).pagination_offset).to eq(3)
    end
  end
end
