# frozen_string_literal: true

require "rails_helper"

describe ImageFilter do
  let(:image_url) { "http://example.com/image.jpg" }
  let(:filter) { described_class.new(input) }

  context "when img has no src" do
    let(:input) { '<img class="foo">' }

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end
  end

  context "when img has no size attributes" do
    let(:input) { "<img src=\"#{image_url}\">" }
    let(:output) { "<img src=\"#{image_url}\" width=\"640\" height=\"480\">" }

    it "fetches the image size" do
      allow(FastImage).to receive(:size)
        .with(image_url, timeout: 2.0)
        .and_return([640, 480])
      expect(filter.to_html).to eq(output)
    end
  end

  context "when img has only one size attribute" do
    let(:input) { "<img width=\"320\" src=\"#{image_url}\">" }
    let(:output) { "<img width=\"640\" src=\"#{image_url}\" height=\"480\">" }

    it "fetches the image size" do
      allow(FastImage).to receive(:size)
        .with(image_url, timeout: 2.0)
        .and_return([640, 480])
      expect(filter.to_html).to eq(output)
    end
  end

  context "when the size has already been fetched", :cache do
    let(:input) { "<img src=\"#{image_url}\">" }
    let(:output) { "<img src=\"#{image_url}\" width=\"640\" height=\"480\">" }

    before do
      allow(FastImage).to receive(:size)
        .with(image_url, timeout: 2.0)
        .and_return([640, 480])
      described_class.new(input).to_html
    end

    it "does not fetch the image size again" do
      filter.to_html
      expect(FastImage).to have_received(:size).once
    end

    it "sets the dimensions from the cache" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when the size could not be determined", :cache do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      allow(FastImage).to receive(:size).and_return(nil)
      described_class.new(input).to_html
    end

    it "does not fetch the image size again" do
      filter.to_html
      expect(FastImage).to have_received(:size).once
    end

    it "fetches the image size again an hour later" do
      travel(2.hours) { filter.to_html }
      expect(FastImage).to have_received(:size).twice
    end
  end

  context "when fetching the image size raises an error" do
    let(:input) { "<img src=\"#{image_url}\">" }

    before do
      allow(FastImage).to receive(:size).and_raise(Errno::EPIPE)
      allow(filter.logger).to receive(:error)
    end

    it "logs the error" do
      filter.to_html
      expect(filter.logger).to have_received(:error).with(/Errno::EPIPE/)
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end
  end

  context "when img has both size attributes" do
    let(:input) { "<img width=\"320\" height=\"240\" src=\"#{image_url}\">" }

    it "does not call FastImage" do
      allow(FastImage).to receive(:size).and_return(nil)
      input
      expect(FastImage).not_to have_received(:size)
    end

    it "is not touched" do
      expect(filter.to_html).to eq(input)
    end
  end
end
