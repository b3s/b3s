# frozen_string_literal: true

require "rails_helper"

describe PostImage do
  it { is_expected.to be_a(DynamicImage::Model) }

  describe "validations" do
    subject(:image) { build(:post_image, file:) }

    let(:file) do
      Rack::Test::UploadedFile.new(Rails.root.join("spec/support/#{filename}"))
    end

    context "when the image is within the pixel limit" do
      let(:filename) { "pink.png" }

      it { is_expected.to be_valid }
    end

    context "when the image is over the pixel limit" do
      let(:filename) { "huge.png" }

      it "rejects the image" do
        image.valid?
        expect(image.errors[:data])
          .to include("is too large (the limit is 250 megapixels)")
      end
    end

    context "when the frames of an animated image add up to over the pixel limit" do
      let(:filename) { "huge_animated.gif" }

      it "rejects the image" do
        image.valid?
        expect(image.errors[:data])
          .to include("is too large (the limit is 250 megapixels)")
      end
    end
  end
end
