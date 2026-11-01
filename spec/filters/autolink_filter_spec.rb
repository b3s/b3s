# frozen_string_literal: true

require "rails_helper"

describe AutolinkFilter do
  subject(:filter) { described_class.new(input) }

  before do
    OEmbed::Providers.register_all(access_tokens: { facebook: "my-token" })
  end

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

    let(:oembed_request) do
      stub_request(
        :get,
        "https://graph.facebook.com/v8.0/instagram_oembed?access_token=" \
        "my-token&format=json&url=https://www.instagram.com/p/8ql-VChPSZ/"
      )
    end

    let(:provider_response) { { status: 200, body: instagram_embed } }

    before { oembed_request.to_return(provider_response) }

    it "converts it to an embed" do
      expect(filter.to_html).to(
        eq("<div class=\"embed\" data-oembed-url=\"#{input}\">" \
           "#{instagram_json['html']}</div>")
      )
    end

    it "caches the response" do
      filter.to_html
      expect(OembedResponse.find_by(url: input).html).to eq(instagram_json["html"].strip)
    end

    context "when the response is cached" do
      before { OembedResponse.store(input, "<blockquote>cached</blockquote>") }

      it "uses the cached response" do
        expect(filter.to_html).to(
          eq("<div class=\"embed\" data-oembed-url=\"#{input}\">" \
             "<blockquote>cached</blockquote></div>")
        )
      end

      it "does not request the provider" do
        filter.to_html
        expect(oembed_request).not_to have_been_requested
      end
    end

    context "when the provider request fails" do
      let(:provider_response) { { status: 500 } }

      it "falls back to a link" do
        expect(filter.to_html).to eq("<a href=\"#{input}\">#{input}</a>")
      end

      it "does not cache the response" do
        filter.to_html
        expect(OembedResponse.exists?(url: input)).to be(false)
      end
    end
  end
end
