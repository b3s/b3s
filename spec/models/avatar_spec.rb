# frozen_string_literal: true

require "rails_helper"

describe Avatar do
  it { is_expected.to have_one(:user) }

  describe "validations" do
    subject(:avatar) { build(:avatar, file:) }

    let(:file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/#{filename}"), "image/png"
      )
    end

    context "when the image is within the pixel limit" do
      let(:filename) { "pink.png" }

      it { is_expected.to be_valid }
    end

    context "when the image is over the pixel limit" do
      let(:filename) { "huge.png" }

      it "rejects the image" do
        avatar.valid?
        expect(avatar.errors[:data])
          .to include("is too large (the limit is 250 megapixels)")
      end
    end
  end
end
