# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Uploads" do
  let(:user) { create(:user) }
  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/pink.png"),
      "image/png"
    )
  end

  before { login_as(user) }

  around suppress_stderr: true do |example|
    original_stderr = $stderr.dup
    $stderr.reopen(File::NULL, "w")
    example.run
    $stderr.reopen(original_stderr)
  end

  describe "POST /uploads" do
    subject { response }

    before do
      post uploads_path,
           params: { upload: { file: } },
           headers: { "Accept" => "application/json" }
    end

    context "when not authenticated" do
      let(:user) { nil }

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "when user is banned" do
      let(:user) { create(:user, :banned) }

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "with a valid file" do
      let(:last_image) { PostImage.last }
      let(:expected_response) do
        { type: "image/png",
          name: "pink.png",
          embed: "[image:#{last_image.id}:" \
                 "76a68c6a781ef4919bd4352b880b7c9e50de3d96]" }
      end

      it "responds with JSON" do
        expect(response.content_type).to match "application/json"
      end

      it "returns the expected JSON response" do
        expect(response.parsed_body).to eq(
          JSON.parse(expected_response.to_json)
        )
      end

      it "creates a PostImage record" do
        expect(PostImage.count).to eq(1)
      end
    end

    context "with an invalid image file" do
      let(:file) do
        Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/invalid_header.png"),
          "image/png"
        )
      end

      it { is_expected.to have_http_status(:ok) }

      it "returns an empty JSON response" do
        expect(response.parsed_body).to eq({})
      end

      it "does not create a PostImage record" do
        expect(PostImage.count).to eq(0)
      end
    end

    context "with a corrupted image file", :suppress_stderr do
      let(:file) do
        Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/corrupted.png"),
          "image/png"
        )
      end

      it { is_expected.to have_http_status(:internal_server_error) }

      it "returns an error message" do
        expect(response.parsed_body["error"]).to eq("Invalid image")
      end
    end

    context "with a duplicate file" do
      let!(:existing_image) { PostImage.last }

      before do
        post uploads_path,
             params: { upload: { file: } },
             headers: { "Accept" => "application/json" }
      end

      it "does not create a new PostImage record" do
        expect(PostImage.count).to eq(1)
      end

      it "returns the existing PostImage" do
        expect(response.parsed_body["embed"])
          .to(include(existing_image.id.to_s))
      end
    end
  end
end
