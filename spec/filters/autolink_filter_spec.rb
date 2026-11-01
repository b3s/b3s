# frozen_string_literal: true

require "rails_helper"

describe AutolinkFilter do
  subject(:filter) { described_class.new(input) }

  context "when input contains a URL" do
    let(:input) { "http://example.com/foo?bar=1" }
    let(:output) { "<a href=\"#{input}\">#{input}</a>" }

    it "embeds the image" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a URL to a PNG file" do
    let(:input) { "http://example.com/folder/image.png" }
    let(:output) { '<img src="http://example.com/folder/image.png">' }

    it "embeds the image" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a URL to a JPEG file" do
    let(:input) { "http://example.com/folder/image.jpg" }
    let(:output) { '<img src="http://example.com/folder/image.jpg">' }

    it "embeds the image" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a URL to a WebP file" do
    let(:input) { "http://example.com/folder/image.webp" }
    let(:output) { '<img src="http://example.com/folder/image.webp">' }

    it "embeds the image" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a URL to an AVIF file" do
    let(:input) { "http://example.com/folder/image.avif" }
    let(:output) { '<img src="http://example.com/folder/image.avif">' }

    it "embeds the image" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains an image tag" do
    let(:input) { '<img src="http://example.com/folder/image.jpg">' }

    it "leaves it alone" do
      expect(filter.to_html).to eq(input)
    end
  end

  context "when input contains a URL to a GIFV file" do
    let(:input) { "http://i.imgur.com/abcdefg.gifv" }
    let(:output) { '<img src="http://i.imgur.com/abcdefg.gif">' }

    it "embeds it as a GIF" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when URL is an Instagram photo" do
    let(:instagram_embed) do
      Rails.root.join("spec/support/requests/instagram_embed.json").read
    end
    let(:instagram_json) { JSON.parse(instagram_embed) }
    let(:input) { "https://www.instagram.com/p/8ql-VChPSZ/" }

    before do
      stub_request(
        :get,
        "https://graph.facebook.com/v26.0/instagram_oembed?" \
        "format=json&url=https://www.instagram.com/p/8ql-VChPSZ/"
      ).to_return(status: 200, body: instagram_embed)
    end

    it "converts it to an embed" do
      expect(filter.to_html).to(
        eq("<div class=\"embed\" data-oembed-url=\"#{input}\">" \
           "#{instagram_json['html']}</div>")
      )
    end
  end

  context "when URL is a Facebook video" do
    let(:input) { "https://www.facebook.com/facebook/videos/10153231379946729/" }
    let(:html) { '<div class="fb-video"></div>' }

    before do
      stub_request(:get, "https://graph.facebook.com/v26.0/oembed_video")
        .with(query: { format: "json", url: input })
        .to_return(status: 200, body: { type: "video", version: "1.0", html: }.to_json)
    end

    it "converts it to an embed" do
      expect(filter.to_html).to(
        eq("<div class=\"embed\" data-oembed-url=\"#{input}\">#{html}</div>")
      )
    end
  end
end
