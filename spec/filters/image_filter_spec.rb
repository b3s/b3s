# frozen_string_literal: true

require "rails_helper"

describe ImageFilter do
  let(:image_url) { "http://example.com/image.png" }
  let(:image) { Rails.root.join("spec/support/pink.png").binread }
  let(:filter) { described_class.new(input) }

  before do
    dns = instance_double(Resolv::DNS, :timeouts= => nil)
    allow(dns).to receive(:getaddresses) { |host| Resolv.getaddresses(host) }
    allow(Resolv::DNS).to receive(:new).and_return(dns)
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with("example.com").and_return(["93.184.215.14"])
  end

  context "when img has no src" do
    let(:input) { '<img class="foo">' }

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end
  end

  context "when img has no size attributes" do
    let(:input) { "<img src=\"#{image_url}\">" }
    let(:output) { "<img src=\"#{image_url}\" width=\"16\" height=\"16\">" }

    before { stub_request(:get, image_url).to_return(body: image) }

    it "fetches the image size" do
      expect(filter.to_html).to eq(output)
    end

    it "only requests the start of the image" do
      filter.to_html
      expect(a_request(:get, image_url).with(headers: { "Range" => "bytes=0-65535" }))
        .to have_been_made.once
    end

    it "bounds DNS lookups" do
      filter.to_html
      expect(Resolv::DNS.new).to have_received(:timeouts=).with(1)
    end
  end

  context "when the image is on a public IP address" do
    let(:input) { "<img src=\"http://93.184.215.14/image.png\">" }

    before { stub_request(:get, "http://93.184.215.14/image.png").to_return(body: image) }

    it "fetches the image size" do
      expect(filter.to_html).to include('width="16" height="16"')
    end
  end

  context "when the server responds with partial content" do
    let(:input) { "<img src=\"#{image_url}\">" }
    let(:output) { "<img src=\"#{image_url}\" width=\"16\" height=\"16\">" }

    before { stub_request(:get, image_url).to_return(status: 206, body: image) }

    it "fetches the image size" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when img has only one size attribute" do
    let(:input) { "<img width=\"320\" src=\"#{image_url}\">" }
    let(:output) { "<img width=\"16\" src=\"#{image_url}\" height=\"16\">" }

    before { stub_request(:get, image_url).to_return(body: image) }

    it "fetches the image size" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when the image is a data URI" do
    let(:input) { "<img src=\"data:image/png;base64,#{Base64.strict_encode64(image)}\">" }

    it "sets the dimensions" do
      expect(filter.to_html).to include('width="16" height="16"')
    end
  end

  context "when the image redirects to a public address" do
    let(:input) { "<img src=\"#{image_url}\">" }
    let(:output) { "<img src=\"#{image_url}\" width=\"16\" height=\"16\">" }

    before do
      stub_request(:get, image_url)
        .to_return(status: 302, headers: { "Location" => "http://example.com/other.png" })
      stub_request(:get, "http://example.com/other.png").to_return(body: image)
    end

    it "follows the redirect" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when the image redirects too many times" do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      stub_request(:get, %r{\Ahttp://example\.com/})
        .to_return(status: 302, headers: { "Location" => image_url })
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end

    it "stops after three redirects" do
      filter.to_html
      expect(a_request(:get, image_url)).to have_been_made.times(4)
    end
  end

  shared_examples "a blocked image" do
    let(:input) { "<img src=\"#{url}\">" }

    before { stub_request(:any, //).to_return(body: image) }

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end

    it "does not request the image" do
      filter.to_html
      expect(a_request(:any, //)).not_to have_been_made
    end
  end

  context "when the image is on a loopback address" do
    it_behaves_like "a blocked image" do
      let(:url) { "http://127.0.0.1/image.png" }
    end
  end

  context "when the image is on an IPv6 loopback address" do
    it_behaves_like "a blocked image" do
      let(:url) { "http://[::1]/image.png" }
    end
  end

  context "when the image is on a private address" do
    it_behaves_like "a blocked image" do
      let(:url) { "http://10.0.0.1:8080/image.png" }
    end
  end

  context "when the image is on a link-local address" do
    it_behaves_like "a blocked image" do
      let(:url) { "http://169.254.169.254/latest/meta-data/" }
    end
  end

  context "when the image is on an IPv6 link-local address" do
    it_behaves_like "a blocked image" do
      let(:url) { "http://[fe80::1]/image.png" }
    end
  end

  context "when the hostname resolves to a private address" do
    before do
      allow(Resolv).to receive(:getaddresses).with("internal.example.com").and_return(["192.168.1.10"])
    end

    it_behaves_like "a blocked image" do
      let(:url) { "http://internal.example.com/image.png" }
    end
  end

  context "when the hostname resolves to a link-local address" do
    before do
      allow(Resolv).to receive(:getaddresses).with("internal.example.com").and_return(["169.254.169.254"])
    end

    it_behaves_like "a blocked image" do
      let(:url) { "https://internal.example.com/image.png" }
    end
  end

  context "when the image is a local file" do
    it_behaves_like "a blocked image" do
      let(:url) { Rails.root.join("spec/support/pink.png").to_s }
    end
  end

  context "when the image uses an unsupported scheme" do
    it_behaves_like "a blocked image" do
      let(:url) { "ftp://example.com/image.png" }
    end
  end

  context "when the image redirects to a private address" do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      stub_request(:get, image_url)
        .to_return(status: 302, headers: { "Location" => "http://127.0.0.1/image.png" })
      stub_request(:get, "http://127.0.0.1/image.png").to_return(body: image)
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end

    it "does not follow the redirect" do
      filter.to_html
      expect(a_request(:get, "http://127.0.0.1/image.png")).not_to have_been_made
    end
  end

  context "when the image redirects to a hostname resolving to a private address" do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      allow(Resolv).to receive(:getaddresses).with("internal.example.com").and_return(["10.1.2.3"])
      stub_request(:get, image_url)
        .to_return(status: 301, headers: { "Location" => "http://internal.example.com/image.png" })
      stub_request(:get, "http://internal.example.com/image.png").to_return(body: image)
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end

    it "does not follow the redirect" do
      filter.to_html
      expect(a_request(:get, "http://internal.example.com/image.png")).not_to have_been_made
    end
  end

  context "when the size has already been fetched", :cache do
    let(:input) { "<img src=\"#{image_url}\">" }
    let(:output) { "<img src=\"#{image_url}\" width=\"16\" height=\"16\">" }

    before do
      stub_request(:get, image_url).to_return(body: image)
      described_class.new(input).to_html
    end

    it "does not fetch the image size again" do
      filter.to_html
      expect(a_request(:get, image_url)).to have_been_made.once
    end

    it "sets the dimensions from the cache" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when the size could not be determined", :cache do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      stub_request(:get, image_url).to_return(status: 404)
      described_class.new(input).to_html
    end

    it "does not fetch the image size again" do
      filter.to_html
      expect(a_request(:get, image_url)).to have_been_made.once
    end

    it "fetches the image size again an hour later" do
      travel(2.hours) { filter.to_html }
      expect(a_request(:get, image_url)).to have_been_made.twice
    end
  end

  context "when the request times out" do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      stub_request(:get, image_url).to_timeout
      allow(filter.logger).to receive(:error)
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end

    it "does not log an error" do
      filter.to_html
      expect(filter.logger).not_to have_received(:error)
    end
  end

  context "when the response stalls past the wall-clock limit", :cache do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:read_body) { sleep 1 }
      allow(SsrfFilter).to receive(:get).and_yield(response)
      allow(Timeout).to receive(:timeout).and_wrap_original do |original, _, &block|
        original.call(0.01, &block)
      end
    end

    it "limits the probe to five seconds" do
      filter.to_html
      expect(Timeout).to have_received(:timeout).with(5)
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end

    it "caches the failure" do
      filter.to_html
      described_class.new(input).to_html
      expect(SsrfFilter).to have_received(:get).once
    end
  end

  context "when fetching the image size raises an error" do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      stub_request(:get, image_url).to_raise(StandardError.new("foo"))
      allow(filter.logger).to receive(:error)
    end

    it "logs the error" do
      filter.to_html
      expect(filter.logger).to have_received(:error).with("Unexpected connection error #<StandardError: foo>")
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end
  end

  context "when the data URI is larger than the sanitizer allows" do
    let(:padded_image) { image + ("\0" * UrlPolicy::DATA_IMAGE_MAX_BYTES) }
    let(:input) { "<img src=\"data:image/png;base64,#{Base64.strict_encode64(padded_image)}\">" }

    before { allow(FastImage).to receive(:size).and_call_original }

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end

    it "does not decode the image" do
      filter.to_html
      expect(FastImage).not_to have_received(:size)
    end
  end

  context "with a stubbed clock" do
    let(:clock) { { now: 0.0 } }

    before do
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC) { clock[:now] }
    end

    context "when the server trickles the response" do
      let(:input) { "<img src=\"#{image_url}\">" }

      before do
        response = Net::HTTPOK.new("1.1", "200", "OK")
        allow(response).to receive(:read_body) do |&block|
          100.times do
            clock[:now] += 1
            block.call("\0")
          end
        end
        allow(SsrfFilter).to receive(:get).and_yield(response)
        allow(FastImage).to receive(:size).and_call_original
      end

      it "is not touched" do
        expect(filter.to_html).to eq(input)
      end

      it "stops reading at the deadline" do
        filter.to_html
        expect(FastImage).to have_received(:size).exactly(3).times
      end
    end

    context "when the DNS lookup runs past the deadline" do
      let(:input) { "<img src=\"#{image_url}\">" }

      before do
        allow(Resolv).to receive(:getaddresses).with("example.com") do
          clock[:now] += 4
          ["93.184.215.14"]
        end
        stub_request(:get, image_url).to_return(body: image)
      end

      it "is not touched" do
        expect(filter.to_html).to eq(input)
      end

      it "does not connect" do
        filter.to_html
        expect(a_request(:get, image_url)).not_to have_been_made
      end
    end

    context "when the deadline has passed before the DNS lookup" do
      let(:input) { "<img src=\"#{image_url}\">" }

      before do
        stub_request(:get, image_url).to_return do
          clock[:now] += 4
          { status: 302, headers: { "Location" => "http://other.example.com/image.png" } }
        end
        allow(Resolv).to receive(:getaddresses).with("other.example.com").and_return(["93.184.215.15"])
      end

      it "does not look up the host" do
        filter.to_html
        expect(Resolv).not_to have_received(:getaddresses).with("other.example.com")
      end
    end

    context "when redirects run past the deadline" do
      let(:input) { "<img src=\"#{image_url}\">" }

      before do
        stub_request(:get, %r{\Ahttp://example\.com/}).to_return do
          clock[:now] += 2
          { status: 302, headers: { "Location" => image_url } }
        end
      end

      it "is not touched" do
        expect(filter.to_html).to eq(input)
      end

      it "stops following redirects" do
        filter.to_html
        expect(a_request(:get, image_url)).to have_been_made.twice
      end
    end

    context "when probing exceeds the render budget" do
      let(:input) { Array.new(3) { |i| "<img src=\"http://example.com/#{i}.png\">" }.join }

      before do
        stub_request(:get, %r{\Ahttp://example\.com/}).to_return do
          clock[:now] += 4
          { body: image }
        end
      end

      it "stops probing" do
        filter.to_html
        expect(a_request(:get, "http://example.com/2.png")).not_to have_been_made
      end

      it "sets the dimensions of the probed images" do
        expect(filter.to_html.scan('width="16"').length).to eq(2)
      end
    end
  end

  context "when the dimensions are known before the whole image is read" do
    let(:input) { "<img src=\"#{image_url}\">" }
    let(:read_chunks) { [] }

    before do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:read_body) do |&block|
        (image + ("\0" * 60_000)).bytes.each_slice(512) do |bytes|
          read_chunks << bytes
          block.call(bytes.pack("C*"))
        end
      end
      allow(SsrfFilter).to receive(:get).and_yield(response)
    end

    it "fetches the image size" do
      expect(filter.to_html).to include('width="16" height="16"')
    end

    it "stops reading after the first chunk" do
      filter.to_html
      expect(read_chunks.length).to eq(1)
    end
  end

  context "when a post has more images than the probe limit" do
    let(:urls) { Array.new(27) { |i| "http://example.com/#{i}.png" } }
    let(:input) { urls.map { |url| "<img src=\"#{url}\">" }.join }

    before { stub_request(:get, %r{\Ahttp://example\.com/}).to_return(body: image) }

    it "stops probing" do
      filter.to_html
      expect(a_request(:get, %r{\Ahttp://example\.com/})).to have_been_made.times(25)
    end

    it "does not cache the skipped images", :cache do
      filter.to_html
      described_class.new(input).to_html
      expect(a_request(:get, urls.last)).to have_been_made.once
    end

    it "does not count cached images", :cache do
      described_class.new(urls.first(25).map { |url| "<img src=\"#{url}\">" }.join).to_html
      expect(filter.to_html.scan('width="16"').length).to eq(27)
    end
  end

  context "when img has both size attributes" do
    let(:input) { "<img width=\"320\" height=\"240\" src=\"#{image_url}\">" }

    before { stub_request(:any, //) }

    it "does not request the image" do
      filter.to_html
      expect(a_request(:any, //)).not_to have_been_made
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end
  end
end
