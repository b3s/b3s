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

    context "when the block returns nothing", :cache do
      before { described_class.html_for(url) { nil } }

      it "does not store a response" do
        expect(described_class.exists?(url:)).to be(false)
      end

      it "does not call the block again within a day" do
        travel(23.hours) do
          expect { |block| described_class.html_for(url, &block) }.not_to yield_control
        end
      end

      it "calls the block again after a day" do
        travel(25.hours) do
          expect { |block| described_class.html_for(url, &block) }.to yield_control
        end
      end
    end

    context "when the block reports a temporary failure", :cache do
      before { described_class.html_for(url) { :temporary } }

      it "returns the cached failure" do
        expect(described_class.html_for(url) { "<iframe>fresh</iframe>" }).to eq(:temporary)
      end

      it "calls the block again when refetching temporary failures" do
        expect(described_class.html_for(url, refetch_temporary: true) { "<iframe>fresh</iframe>" })
          .to eq("<iframe>fresh</iframe>")
      end
    end

    context "when the block reports a gone failure", :cache do
      before { described_class.html_for(url) { :gone } }

      it "doesn't call the block when refetching temporary failures" do
        expect { |block| described_class.html_for(url, refetch_temporary: true, &block) }.not_to yield_control
      end

      it "returns the cached failure" do
        expect(described_class.html_for(url, refetch_temporary: true) { "<iframe>fresh</iframe>" }).to eq(:gone)
      end
    end

    context "when an older failure entry is cached", :cache do
      before { Rails.cache.write("oembed-failure/#{Digest::SHA256.hexdigest(url)}", true) }

      it "treats it as temporary" do
        expect(described_class.html_for(url, refetch_temporary: true) { "<iframe>fresh</iframe>" })
          .to eq("<iframe>fresh</iframe>")
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

    context "when given an age in days" do
      let(:options) { { older_than_days: 30 } }

      it { is_expected.to eq(1) }

      it "deletes responses fetched before the cutoff" do
        purge
        expect(described_class.pluck(:url)).to eq([url])
      end
    end

    context "when the age is zero" do
      let(:options) { { older_than_days: 0 } }

      it "raises an error" do
        expect { purge }.to raise_error(ArgumentError)
      end
    end

    context "when the age is negative" do
      let(:options) { { older_than_days: -1 } }

      it "raises an error" do
        expect { purge }.to raise_error(ArgumentError)
      end
    end

    context "when doing a dry run" do
      let(:options) { { older_than_days: 30, dry_run: true } }

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
