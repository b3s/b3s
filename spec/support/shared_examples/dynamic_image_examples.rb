# frozen_string_literal: true

RSpec.shared_examples "an image response" do
  it { is_expected.to have_http_status(:success) }

  it "returns image content type" do
    expect(response.content_type).to match(/image/)
  end
end

RSpec.shared_examples "a DynamicImage controller" do |factory_name|
  include DynamicImage::Helper

  subject { response }

  let(:record) { create(factory_name) }

  describe "default action" do
    before { get dynamic_image_path(record) }

    it_behaves_like "an image response"

    context "with size parameter" do
      before { get dynamic_image_path(record, size: "100x100") }

      it_behaves_like "an image response"
    end
  end

  describe "uncropped action" do
    before { get dynamic_image_path(record, action: :uncropped) }

    it_behaves_like "an image response"
  end

  describe "original action" do
    before { get dynamic_image_path(record, action: :original) }

    it_behaves_like "an image response"
  end

  describe "download action" do
    before { get dynamic_image_path(record, action: :download) }

    it_behaves_like "an image response"

    it "sets content disposition header" do
      expect(response.headers["Content-Disposition"]).to be_present
    end
  end
end
