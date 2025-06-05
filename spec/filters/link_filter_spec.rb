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

    context "when the image exists" do
      it "rewrites the URL to one without protocol" do
        req = stub_request(:head, "https://example.com/image.jpg")
              .to_return(status: 200)
        expect(filter.to_html).to eq('<img src="//example.com/image.jpg">')
        assert_requested(req)
      end
    end

    context "when the image doesn't exists" do
      it "does not change the URL" do
        req = stub_request(:head, "https://example.com/image.jpg")
              .to_return(status: 404)
        expect(filter.to_html).to eq(input)
        assert_requested(req)
      end
    end

    context "when the server doesn't respond" do
      it "does not change the URL" do
        req = stub_request(:head, "https://example.com/image.jpg")
              .to_raise(SocketError)
        expect(filter.to_html).to eq(input)
        assert_requested(req)
      end
    end

    context "when an unexpected error occurs" do
      before do
        stub_request(:head, "https://example.com/image.jpg").to_raise("foo")
        allow(filter.logger).to receive(:error)
      end

      it "logs the error" do
        filter.to_html
        expect(filter.logger).to(
          have_received(:error)
            .with("Unexpected connection error #<StandardError: foo>")
        )
      end

      it "returns the input" do
        expect(filter.to_html).to eq(input)
      end
    end
  end
end
