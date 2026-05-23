# frozen_string_literal: true

require "rails_helper"

describe Paginatable do
  before do
    Exchange.per_page = 2
  end

  describe ".page" do
    let(:paginated) { Exchange.page(2, context: 1) }

    specify { expect(paginated.offset_value).to eq(1) }
    specify { expect(paginated.limit_value).to eq(3) }
  end

  describe ".context" do
    specify { expect(Exchange.page(1, context: 3).context).to eq(0) }
    specify { expect(Exchange.page(2, context: 3).context).to eq(3) }
  end

  describe ".context?" do
    specify { expect(Exchange.page(1).context?).to be(false) }
    specify { expect(Exchange.page(1, context: 3).context?).to be(false) }
    specify { expect(Exchange.page(2, context: 3).context?).to be(true) }
  end

  describe ".total_pages" do
    before { create_list(:post, 3) }

    specify { expect(Exchange.page(2, context: 1).total_pages).to eq(2) }
  end

  describe ".current_page" do
    before { create_list(:exchange, 3) }

    specify { expect(Exchange.page(0).current_page).to eq(1) }
    specify { expect(Exchange.page(1).current_page).to eq(1) }
    specify { expect(Exchange.page(2).current_page).to eq(2) }
    specify { expect(Exchange.page(3).current_page).to eq(2) }
    specify { expect(Exchange.page(2, context: 2).current_page).to eq(2) }
  end

  describe ".first_page" do
    specify { expect(Exchange.page(2).first_page).to eq(1) }
  end

  describe ".last_page" do
    before { create_list(:exchange, 3) }

    specify { expect(Exchange.page(1).last_page).to eq(2) }
  end

  describe ".first_page?" do
    before { create_list(:exchange, 3) }

    specify { expect(Exchange.page(1).first_page?).to be(true) }
    specify { expect(Exchange.page(2).first_page?).to be(false) }
  end

  describe ".last_page?" do
    before { create_list(:exchange, 3) }

    specify { expect(Exchange.page(1).last_page?).to be(false) }
    specify { expect(Exchange.page(2).last_page?).to be(true) }
  end

  describe ".previous_page" do
    before { create_list(:exchange, 3) }

    specify { expect(Exchange.page(2).previous_page).to eq(1) }
    specify { expect(Exchange.page(1).previous_page).to be_nil }
  end

  describe ".next_page" do
    before { create_list(:exchange, 3) }

    specify { expect(Exchange.page(1).next_page).to eq(2) }
    specify { expect(Exchange.page(2).next_page).to be_nil }
  end

  describe ".total_count" do
    before { create_list(:exchange, 3) }

    it "ignores limit" do
      expect(Exchange.limit(1).total_count).to eq(3)
    end

    it "ignores offset" do
      expect(Exchange.offset(1).total_count).to eq(3)
    end

    it "memoizes the count on a paginated scope across calls" do
      scope = Exchange.page(1)
      queries = count_queries(matching: "COUNT") { 3.times { scope.total_pages } }
      expect(queries).to eq(1)
    end
  end

  describe ".per_page" do
    before { Exchange.per_page = 19 }

    specify { expect(Exchange.per_page).to eq(19) }
  end
end
