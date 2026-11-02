# frozen_string_literal: true

require "rails_helper"

describe ImageFetcher do
  describe ".fetch" do
    subject { described_class.fetch(body) }

    let(:url) { "https://i.imgur.com/foobar.png" }
    let(:image) { PostImage.last }
    let(:body) { url.to_s }

    before do
      stub_request(:get, url)
        .to_return(
          status: 200,
          body: Rails.root.join("spec/support/pink.png").open("rb"),
          headers: { "Content-Type" => "image/png" }
        )
    end

    context "when image is autolinked" do
      it { is_expected.to eq("[image:#{image.id}:#{image.content_hash}]") }
    end

    context "when image is embedded with Markdown" do
      let(:body) { "![This is an image](#{url})" }

      it { is_expected.to eq("[image:#{image.id}:#{image.content_hash}]") }
    end

    context "when image is embedded with <img> tag" do
      let(:body) { "<img src=\"#{url}\" alt=\"foo\">" }

      it { is_expected.to eq("[image:#{image.id}:#{image.content_hash}]") }
    end

    context "when image is embedded with <img /> tag" do
      let(:body) { "<img src=\"#{url}\" alt=\"foo\" />" }

      it { is_expected.to eq("[image:#{image.id}:#{image.content_hash}]") }
    end

    context "when image is embedded with <img/> tag" do
      let(:body) { "<img src=\"#{url}\" alt=\"foo\"/>" }

      it { is_expected.to eq("[image:#{image.id}:#{image.content_hash}]") }
    end

    context "when image is not on the whitelist" do
      let(:body) { "http://example.com/example.jpg" }

      it { is_expected.to eq(body) }
    end

    context "when image is not on the whitelist, Markdown syntax" do
      let(:body) { "![](http://example.com/example.jpg)" }

      it { is_expected.to eq(body) }
    end

    %w[http ftp gopher].each do |scheme|
      context "when image URL uses #{scheme}" do
        let(:body) { "<img src=\"#{scheme}://i.imgur.com/foobar.png\">" }

        it { is_expected.to eq(body) }

        it "doesn't request the image" do
          described_class.fetch(body)
          expect(a_request(:any, /i\.imgur\.com/)).not_to have_been_made
        end
      end
    end

    context "when image has already been fetched" do
      let!(:image) { create(:post_image, original_url: url) }

      it { is_expected.to eq("[image:#{image.id}:#{image.content_hash}]") }
    end

    context "when image doesn't exist" do
      before do
        stub_request(:get, url)
          .to_return(status: 404, body: "Not Found")
      end

      it { is_expected.to eq(body) }
    end

    context "when the body has more images than the fetch limit" do
      let(:body) { Array.new(26) { |i| "https://i.imgur.com/#{i}.png" }.join(" ") }

      before do
        stub_request(:get, %r{\Ahttps://i\.imgur\.com/})
          .to_return(status: 404)
      end

      it "stops fetching" do
        described_class.fetch(body)
        expect(a_request(:get, %r{\Ahttps://i\.imgur\.com/})).to have_been_made.times(25)
      end
    end

    context "when the fetch budget is already spent" do
      subject { described_class.fetch(body, fetch_budget:) }

      let(:fetch_budget) { instance_double(FetchBudget, spend?: false) }

      it { is_expected.to eq(body) }
    end

    context "when image is over the pixel limit" do
      before do
        stub_request(:get, url)
          .to_return(
            status: 200,
            body: Rails.root.join("spec/support/huge.png").open("rb"),
            headers: { "Content-Type" => "image/png" }
          )
      end

      it { is_expected.to eq(body) }

      it "doesn't store the image" do
        expect { described_class.fetch(body) }.not_to change(PostImage, :count)
      end
    end

    it "gets the filename" do
      described_class.fetch(body)
      expect(image.filename).to eq("foobar.png")
    end

    it "gets the content type" do
      described_class.fetch(body)
      expect(image.content_type).to eq("image/png")
    end

    it "bounds the request time" do
      allow(Typhoeus).to receive(:get).and_call_original
      described_class.fetch(body)
      expect(Typhoeus).to have_received(:get).with(url, timeout: 15, connecttimeout: 2)
    end

    it "sets the original URL" do
      described_class.fetch(body)
      expect(image.original_url).to eq(url)
    end
  end
end
