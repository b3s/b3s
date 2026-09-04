# frozen_string_literal: true

require "rails_helper"

describe Renderer do
  describe ".filters" do
    subject(:filters) { described_class.filters(format) }

    let(:format) { "markdown" }

    it { is_expected.to include(AutolinkFilter) }
    it { is_expected.to include(CodeFilter) }
    it { is_expected.to include(ImageFilter) }
    it { is_expected.to include(LinkFilter) }
    it { is_expected.to include(SanitizeFilter) }

    context "when format is markdown" do
      it { is_expected.to include(MarkdownFilter) }
      it { is_expected.not_to include(SimpleFilter) }
    end

    context "when format is html" do
      let(:format) { "html" }

      it { is_expected.to include(SimpleFilter) }
      it { is_expected.not_to include(MarkdownFilter) }
    end
  end

  describe ".render" do
    let(:rendered) { described_class.render(input, format:) }

    context "when format is markdown" do
      let(:format) { "markdown" }
      let(:input) { "*markdown*" }
      let(:output) { "<p><em>markdown</em></p>\n" }

      it "renders as Markdown" do
        expect(rendered).to eq(output)
      end
    end

    context "when format is html" do
      let(:format) { "html" }
      let(:input) { "paragraph\n\nparagraph" }
      let(:output) { "paragraph<br>\n<br>\nparagraph" }

      it "renders through SimpleFilter" do
        expect(rendered).to eq(output)
      end
    end

    context "when the post embeds an image" do
      let(:format) { "markdown" }
      let(:image) { create(:post_image, :wide) }
      let(:input) { "look: [image:#{image.id}:#{image.content_hash}]" }

      it "leaves the picture element intact" do
        expect(rendered).to include("<picture>").and(include("</picture>"))
      end

      it "does not nest the fallback inside the source" do
        expect(rendered).not_to include("</source>")
      end

      it "returns markup that is safe to render" do
        expect(rendered).to be_html_safe
      end
    end
  end
end
