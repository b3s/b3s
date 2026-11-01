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

  context "when input contains a URL with HTML characters" do
    let(:input) { "http://example.com/?a=1&b='x'" }
    let(:output) do
      '<a href="http://example.com/?a=1&amp;b=&#39;x&#39;">' \
        "http://example.com/?a=1&amp;b=&#39;x&#39;</a>"
    end

    it "escapes the URL" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains an image URL with HTML characters" do
    let(:input) { "http://example.com/a&b'.png" }
    let(:output) { '<img src="http://example.com/a&amp;b&#39;.png">' }

    it "escapes the URL" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when a URL is followed by markup" do
    let(:input) { 'http://example.com/"><script>alert(1)</script>' }

    it "leaves the markup outside the link" do
      expect(filter.to_html).to start_with('<a href="http://example.com/">http://example.com/</a>"><script>')
    end
  end

  {
    "an Instagram photo" => "https://www.instagram.com/p/8ql-VChPSZ/",
    "a Facebook video" => "https://www.facebook.com/facebook/videos/10153231379946729/",
    "a Tumblr post" => "https://staff.tumblr.com/post/123456789",
    "a Giphy GIF" => "https://giphy.com/gifs/cat-funny-JIX9t2j0ZTN9S",
    "a Mastodon post" => "https://mastodon.social/@ghorwood/110149321725092169"
  }.each do |description, url|
    context "when URL is #{description}" do
      let(:input) { url }
      let(:output) do
        "<div class=\"embed\" data-oembed-url=\"#{url}\"><a href=\"#{url}\">#{url}</a></div>"
      end

      it "converts it to an embed placeholder" do
        expect(filter.to_html).to eq(output)
      end

      it "doesn't make a request" do
        filter.to_html
        expect(a_request(:any, //)).not_to have_been_made
      end
    end
  end

  context "when an embeddable URL contains HTML characters" do
    let(:input) { "https://vimeo.com/1?a=1&b='x'" }
    let(:url) { "https://vimeo.com/1?a=1&amp;b=&#39;x&#39;" }

    it "escapes the URL" do
      expect(filter.to_html).to eq(
        "<div class=\"embed\" data-oembed-url=\"#{url}\"><a href=\"#{url}\">#{url}</a></div>"
      )
    end
  end

  %w[
    https://www.ted.com/talks/some_talk
    https://vine.co/v/abc123
    http://www.viddler.com/v/abc123
  ].each do |url|
    context "when URL is from an unregistered provider (#{url})" do
      let(:input) { url }

      it "has no provider" do
        expect(OEmbed::Providers.find(input)).to be_nil
      end

      it "links it" do
        expect(filter.to_html).to eq("<a href=\"#{input}\">#{input}</a>")
      end

      it "doesn't make a request" do
        filter.to_html
        expect(a_request(:any, //)).not_to have_been_made
      end
    end
  end
end
