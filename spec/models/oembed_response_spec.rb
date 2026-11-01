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

  describe ".seed_from_posts" do
    subject(:seed) { described_class.seed_from_posts }

    def embed(url, html)
      "<div class=\"embed\" data-oembed-url=\"#{url}\">#{html}</div>"
    end

    def create_post(body, body_html)
      create(:post, body:, body_html:, skip_preprocess: true)
    end

    before do
      create_post("No embeds here", "<p>No embeds here</p>")
      create_post(url, embed(url, "<iframe>old</iframe>"))
      create_post("Hi\n\n#{url}\nhttps://vimeo.com/1",
                  "<p>Hi</p>#{embed(url, '<iframe>new</iframe>')}" \
                  "#{embed('https://vimeo.com/1', '<iframe>vimeo</iframe>')}")
    end

    it { is_expected.to eq(2) }

    it "stores the most recent embed HTML for each URL" do
      seed
      expect(described_class.order(:url).pluck(:url, :html)).to eq(
        [["https://vimeo.com/1", "<iframe>vimeo</iframe>"],
         [url, "<iframe>new</iframe>"]]
      )
    end

    context "when a URL is already cached" do
      before { described_class.store(url, "<iframe>existing</iframe>") }

      it { is_expected.to eq(1) }

      it "keeps the existing response" do
        seed
        expect(described_class.find_by(url:).html).to eq("<iframe>existing</iframe>")
      end
    end

    context "when an embed was written by hand" do
      before do
        html = embed("https://vimeo.com/2", "<p>Hand-written</p>")
        create_post("https://vimeo.com/2 #{html}", html)
      end

      it "does not seed it" do
        seed
        expect(described_class.exists?(url: "https://vimeo.com/2")).to be(false)
      end
    end

    context "when the embed URL is not in the post body" do
      before { create_post("Nothing to see", embed("https://vimeo.com/2", "<iframe>vimeo</iframe>")) }

      it "does not seed it" do
        seed
        expect(described_class.exists?(url: "https://vimeo.com/2")).to be(false)
      end
    end

    context "when doing a dry run" do
      subject(:seed) { described_class.seed_from_posts(dry_run: true) }

      it { is_expected.to eq(2) }

      it "does not store anything" do
        expect { seed }.not_to change(described_class, :count)
      end
    end
  end
end
