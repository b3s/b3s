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

  describe ".purge" do
    subject(:purge) { described_class.purge(**options) }

    let(:options) { { url: } }

    before do
      described_class.store(url, "<iframe>recent</iframe>", fetched_at: 1.day.ago)
      described_class.store("https://vimeo.com/1", "<iframe>old</iframe>", fetched_at: 60.days.ago)
    end

    context "when given a URL" do
      it { is_expected.to eq(1) }

      it "deletes the response for that URL" do
        purge
        expect(described_class.pluck(:url)).to eq(["https://vimeo.com/1"])
      end
    end

    context "when given a cutoff" do
      let(:options) { { older_than: 30.days.ago } }

      it { is_expected.to eq(1) }

      it "deletes responses fetched before the cutoff" do
        purge
        expect(described_class.pluck(:url)).to eq([url])
      end
    end

    context "when doing a dry run" do
      let(:options) { { older_than: 30.days.ago, dry_run: true } }

      it { is_expected.to eq(1) }

      it "does not delete anything" do
        expect { purge }.not_to change(described_class, :count)
      end
    end

    context "when given neither a URL nor a cutoff" do
      let(:options) { {} }

      it "raises an error" do
        expect { purge }.to raise_error(ArgumentError)
      end
    end
  end
end
