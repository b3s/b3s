# frozen_string_literal: true

require "rails_helper"

describe UploadsController do
  let(:user) { create(:user) }
  let(:png_file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/pink.png"),
      "image/png"
    )
  end

  before do
    # Create the first admin user
    create(:user)
  end

  describe "POST create" do
    before { login(user) }

    context "with a valid file" do
      subject { response.body }

      let(:last_image) { PostImage.last }
      let(:expected_response) do
        {
          type: "image/png",
          name: "pink.png",
          embed: "[image:#{last_image.id}:" \
                 "76a68c6a781ef4919bd4352b880b7c9e50de3d96]"
        }
      end

      before do
        post :create, params: { upload: { file: png_file } }, format: :json
      end

      it "responds with JSON" do
        expect(response.header["Content-Type"]).to match "application/json"
      end

      it "returns the expected JSON response" do
        expect(response.parsed_body).to eq(
          JSON.parse(expected_response.to_json)
        )
      end
    end
  end
end
