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

    it "expands embeds after sanitizing" do
      expect(filters.last(2)).to eq([SanitizeFilter, EmbedFilter])
    end

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
    formats = %w[markdown html]

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

    context "when the post contains an embeddable URL" do
      let(:format) { "markdown" }
      let(:url) { "https://vimeo.com/1" }
      let(:input) { "look: #{url}" }

      before { OembedResponse.store(url, '<iframe src="https://player.vimeo.com/video/1"></iframe><script></script>') }

      it "embeds the cleaned provider HTML" do
        expect(rendered).to include(
          "<div class=\"embed\" data-oembed-url=\"#{url}\">" \
          '<iframe src="https://player.vimeo.com/video/1"></iframe></div>'
        )
      end
    end

    context "when the post contains a YouTube code" do
      let(:format) { "markdown" }
      let(:input) { "!y[A \"title\"](https://youtu.be/abcd)" }

      it "embeds the video" do
        expect(rendered).to eq(
          '<iframe title="A &quot;title&quot;" src="https://www.youtube.com/embed/abcd" ' \
          "frameborder=\"0\" allowfullscreen=\"allowfullscreen\"></iframe>\n"
        )
      end
    end

    context "when the post contains a forged embed placeholder" do
      let(:format) { "markdown" }
      let(:input) do
        '<div class="embed" data-oembed-url="https://example.com/">' \
          '<blockquote class="bluesky-embed" data-bluesky-uri="at://x">x</blockquote></div>'
      end

      it "renders a plain link" do
        expect(rendered.strip).to eq('<a href="https://example.com/">https://example.com/</a>')
      end
    end

    {
      "a script tag inside svg" => "<svg><script>alert(document.domain)</script></svg>",
      "an iframe with srcdoc" => '<iframe srcdoc="&lt;script&gt;alert(1)&lt;/script&gt;"></iframe>',
      "a javascript URL with an encoded tab" => '<a href="java&#9;script:alert(1)">x</a>',
      "an svg animate setting href" =>
        '<svg><a><animate attributeName="href" values="0;javascript:alert(1)"/><text>x</text></a></svg>',
      "a mixed case script tag" => "<ScRiPt>alert(1)</ScRiPt>",
      "math with a script" => "<math><mi><script>alert(1)</script></mi></math>",
      "an svg link with xlink:href" => '<svg><a xlink:href="javascript:alert(1)"><text>x</text></a></svg>',
      "a formaction attribute" => '<button formaction="javascript:alert(1)">x</button>',
      "a base tag" => '<base href="https://evil.example/">',
      "a meta refresh" => '<meta http-equiv="refresh" content="0;url=https://evil.example/">',
      "a data URI iframe" => '<iframe src="data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;"></iframe>',
      "a style tag" => "<style>body { display: none }</style>",
      "a markdown javascript link" => "[x](javascript:alert(1))",
      "a markdown link with an encoded scheme" => "[x](java&#9;script:alert(1))",
      "a markdown image with a javascript URL" => "![x](javascript:alert(1))",
      "a YouTube code with markup in the title" =>
        "!y[\"><script>alert(1)</script>](https://youtu.be/abcd)",
      "a YouTube code with markup in the URL" =>
        "!y[x](https://youtu.be/\"><script>alert(1)</script>)",
      "an autolinked URL followed by markup" =>
        'http://example.com/"><img src=x onerror=alert(1)>'
    }.each do |description, html|
      formats.each do |post_format|
        context "when a #{post_format} post contains #{description}" do
          let(:format) { post_format }
          let(:input) { html }

          it { expect(rendered).to be_free_of_script_vectors }
        end
      end
    end
  end
end
