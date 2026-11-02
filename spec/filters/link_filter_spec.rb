# frozen_string_literal: true

require "rails_helper"

describe LinkFilter do
  let(:filter) { described_class.new(input) }

  context "when input contains a local link" do
    before { B3S.config.domain_names = "b3s.me" }

    let(:input) { '<a href="https://b3s.me/path">foo</a>' }
    let(:output) { '<a href="/path">foo</a>' }

    it "converts the link to a relative one" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a malformed link" do
    before { B3S.config.domain_names = "b3s.me" }

    let(:input) { %(<a href="http://www.example.com/>foo&amp;bar">x</a>) }
    let(:output) { %(<a href="http://www.example.com/&gt;foo&amp;bar">x</a>) }

    it "leaves the link untouched" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a malformed image src" do
    let(:input) { %(<img src="http://www.example.com/>foo&amp;bar">) }
    let(:output) { %(<img src="http://www.example.com/&gt;foo&amp;bar">) }

    it "leaves the image untouched" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains an image on the HTTPS whitelist" do
    let(:input) { '<img src="http://i.imgur.com/test.gif">' }
    let(:output) { '<img src="//i.imgur.com/test.gif">' }

    it "converts the URL to one without protocol" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains an iframe on the HTTPS whitelist" do
    let(:input) { '<iframe src="http://youtube.com/foo"></iframe>' }
    let(:output) { '<iframe src="//youtube.com/foo"></iframe>' }

    it "converts the URL to one without protocol" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains an image not on the HTTPS whitelist" do
    let(:input) { '<img src="http://example.com/image.jpg">' }

    before { stub_request(:any, //) }

    it "does not change the URL" do
      expect(filter.to_html).to eq(input)
    end

    it "does not request the URL" do
      filter.to_html
      expect(a_request(:any, //)).not_to have_been_made
    end
  end

  context "when input contains an HTTP iframe not on the HTTPS whitelist" do
    let(:input) { '<iframe src="http://example.com:8080/embed"></iframe>' }

    before { stub_request(:any, //) }

    it "converts the URL to one without protocol" do
      expect(filter.to_html).to eq('<iframe src="//example.com:8080/embed"></iframe>')
    end

    it "does not request the URL" do
      filter.to_html
      expect(a_request(:any, //)).not_to have_been_made
    end
  end

  context "when input contains an HTTPS iframe not on the HTTPS whitelist" do
    let(:input) { '<iframe src="https://example.com/embed"></iframe>' }

    it "leaves the iframe untouched" do
      expect(filter.to_html).to eq(input)
    end
  end
end
