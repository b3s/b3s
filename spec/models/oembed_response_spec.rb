# frozen_string_literal: true

require "rails_helper"

describe OembedResponse do
  let(:url) { "https://www.youtube.com/watch?v=abc" }

  describe ".html_for" do
    subject(:html) { described_class.html_for(url) { "<iframe>fresh</iframe>" } }

    context "when the URL is cached" do
      before { described_class.store(url, "<iframe>cached</iframe>") }

      it { is_expected.to eq("<iframe>cached</iframe>") }

      it "does not call the block" do
        expect { |block| described_class.html_for(url, &block) }.not_to yield_control
      end
    end

    context "when the URL is not cached" do
      it { is_expected.to eq("<iframe>fresh</iframe>") }

      it "stores the response" do
        html
        expect(described_class.find_by(url:).html).to eq("<iframe>fresh</iframe>")
      end
    end

    context "when the block raises" do
      before do
        described_class.html_for(url) { raise "timeout" }
      rescue RuntimeError
        nil
      end

      it "does not store anything" do
        expect(described_class.exists?(url:)).to be(false)
      end
    end
  end
end
