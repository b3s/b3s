# frozen_string_literal: true

require "rails_helper"

describe PostImageFilter do
  let(:filter) { described_class.new(input) }
  let(:image) { create(:post_image) }
  let(:input) { "[image:#{image.id}:#{image.content_hash}]" }

  context "when input contains an embedded image" do
    it "embeds the image" do
      expect(filter.to_html).to match(
        %r{<img.src="/post_images/([\w\d]+)/16x16/#{image.id}-([\w\d]+)\.png"
           .width="16".height="16"./>}x
      )
    end
  end

  context "when the image is wide enough to render responsively" do
    let(:image) { create(:post_image, :wide) }

    it "embeds a picture element" do
      expect(filter.to_html).to start_with("<picture>")
    end

    it "offers webp candidates at several widths" do
      expect(filter.to_html).to match(
        %r{<source.type="image/webp".srcset="(/post_images/\S+\.webp.\d+w,.){2,}}x
      )
    end

    it "falls back to an img in the stored format" do
      expect(filter.to_html).to match(
        %r{<img.[^>]*src="/post_images/([\w\d]+)/1200x900/#{image.id}-([\w\d]+)\.png"
           .width="1200".height="900"}x
      )
    end

    it "points the full size attribute at the whole image" do
      expect(filter.to_html).to match(
        %r{data-full-src="/post_images/([\w\d]+)/1600x1200/#{image.id}-([\w\d]+)\.png"}x
      )
    end
  end

  context "when the image is animated" do
    let(:image) { create(:post_image, :animated) }

    it "has more than one frame" do
      expect(image.frame_count).to be > 1
    end

    it "is wide enough that only the animation rules out a picture" do
      expect(filter.send(:dynamic_picture, image).widths.many?).to be(true)
    end

    it "embeds a plain image tag" do
      expect(filter.to_html).to start_with("<img")
    end
  end

  context "when the hash is wrong" do
    let(:input) { "[image:#{image.id}:abc123]" }

    it "does not embed the image" do
      expect(filter.to_html).to eq(input)
    end
  end

  context "when image doesn't exist" do
    let(:image) { build(:post_image) }

    it "does not embed the image" do
      expect(filter.to_html).to eq(input)
    end
  end
end
