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

  describe "fetch budget" do
    let(:images) { Array.new(25) { |i| "<img src=\"http://example.com/#{i}.png\">" } }
    let(:input) { [*images, "https://vimeo.com/1"].join("\n\n") }

    before do
      dns = instance_double(Resolv::DNS, :timeouts= => nil)
      allow(dns).to receive(:getaddresses).and_return([Resolv::IPv4.create("93.184.215.14")])
      allow(Resolv::DNS).to receive(:new).and_return(dns)
      stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 404)
      stub_request(:get, %r{\Ahttps://vimeo\.com/api/oembed})
      described_class.render(input)
    end

    it "probes images within the budget" do
      expect(a_request(:get, %r{\Ahttp://example\.com/})).to have_been_made.times(25)
    end

    it "shares the budget between image probes and embeds" do
      expect(a_request(:get, %r{\Ahttps://vimeo\.com/api/oembed})).not_to have_been_made
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
      let(:sandbox) do
        'sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-presentation"'
      end

      before { OembedResponse.store(url, '<iframe src="https://player.vimeo.com/video/1"></iframe><script></script>') }

      it "embeds the cleaned provider HTML" do
        expect(rendered).to include(
          "<div class=\"embed\" data-oembed-url=\"#{url}\">" \
          "<iframe src=\"https://player.vimeo.com/video/1\" #{sandbox}></iframe></div>"
        )
      end
    end

    context "when the post contains a YouTube code" do
      let(:format) { "markdown" }
      let(:input) { "!y[A \"title\"](https://youtu.be/abcd)" }
      let(:sandbox) do
        'sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-presentation"'
      end

      it "embeds the video" do
        expect(rendered).to eq(
          '<iframe title="A &quot;title&quot;" src="https://www.youtube.com/embed/abcd" ' \
          "frameborder=\"0\" allowfullscreen=\"allowfullscreen\" #{sandbox}></iframe>\n"
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
        expect(rendered.strip).to eq(
          '<a href="https://example.com/" rel="nofollow noopener noreferrer ugc">https://example.com/</a>'
        )
      end
    end

    formats.each do |post_format|
      context "when a #{post_format} post has a hand-written placeholder for a registered URL" do
        let(:format) { post_format }
        let(:url) { "https://vimeo.com/1" }
        let(:input) { "<div class=\"embed\" data-oembed-url=\"#{url}\"><b>user</b> <i>content</i></div>" }
        let(:bare) { described_class.render(url, format:) }

        before { OembedResponse.store(url, '<iframe src="https://player.vimeo.com/video/1"></iframe>') }

        it "renders the same embed as the bare URL" do
          expect(Nokogiri::HTML5.fragment(rendered).at_css("div.embed").to_html)
            .to eq(Nokogiri::HTML5.fragment(bare).at_css("div.embed").to_html)
        end
      end

      context "when a #{post_format} post has a hand-written placeholder for an unregistered URL" do
        let(:format) { post_format }
        let(:url) { "https://example.com/" }
        let(:input) { "<div class=\"embed\" data-oembed-url=\"#{url}\"><b>user</b> content</div>" }
        let(:bare) { described_class.render(url, format:) }

        it "renders the same link as the bare URL" do
          expect(Nokogiri::HTML5.fragment(rendered).css("a").to_html)
            .to eq(Nokogiri::HTML5.fragment(bare).css("a").to_html)
        end
      end
    end

    context "when the post has a hand-written YouTube placeholder" do
      let(:format) { "markdown" }
      let(:input) do
        '<div class="youtube-embed" data-youtube-id="abcd" data-youtube-title="A title">' \
          "<b>user content</b></div>"
      end

      it "renders the same as the YouTube code" do
        expect(rendered).to eq(described_class.render("!y[A title](https://youtu.be/abcd)", format:))
      end
    end

    context "when the post contains an HTTP iframe" do
      let(:format) { "html" }
      let(:input) { '<iframe src="http://example.com/embed"></iframe>' }

      it "upgrades the iframe to HTTPS" do
        expect(Nokogiri::HTML5.fragment(rendered).at_css("iframe")["src"]).to eq("https://example.com/embed")
      end
    end

    context "when the post links to the forum itself" do
      let(:format) { "markdown" }
      let(:input) { "https://b3s.me/discussions/1 and https://example.com/" }

      before { B3S.config.domain_names = "b3s.me" }

      it "doesn't mark the internal link as nofollow" do
        expect(Nokogiri::HTML5.fragment(rendered).css("a").map { |a| [a["href"], a["rel"]] }).to eq(
          [["/discussions/1", nil], ["https://example.com/", "nofollow noopener noreferrer ugc"]]
        )
      end
    end

    formats.each do |post_format|
      context "when a #{post_format} post has an iframe host that decodes to invalid UTF-8" do
        let(:format) { post_format }
        let(:input) { '<iframe src="https://%ff/"></iframe>' }

        it { expect(rendered).not_to include("<iframe") }
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

  describe "re-sanitizing the output" do
    formats = %w[markdown html]

    let(:rendered) { described_class.render(input, format:) }

    inputs = SCRIPT_VECTORS.values + [
      "*markdown* with a [link](https://example.com/) and ![image](/a.png)",
      "> quote\n\n<div class=\"spoiler\">secret</div>",
      "```ruby\nputs 1\n```",
      "<table><tr><td style=\"color: red; position: fixed\">x</td></tr></table>",
      "<iframe src=\"//www.youtube.com/embed/abcd\" allow=\"autoplay\"></iframe>",
      "<a href=\"https://example.com/\" target=\"_blank\">x</a> <img src=\"data:image/png;base64,AAAA\">"
    ]

    inputs.product(formats).each_with_index do |(html, post_format), index|
      context "when a #{post_format} post is regression input #{index}" do
        let(:format) { post_format }
        let(:input) { html }

        it "is stable" do
          expect(SanitizeFilter.new(rendered).to_html).to eq(rendered.to_str)
        end
      end
    end

    Rails.root.glob("spec/support/requests/oembed/*.json").each do |path|
      context "when the embed is the #{File.basename(path, '.json')} fixture" do
        let(:fixture) { JSON.parse(File.read(path)) }
        let(:cleaned) { EmbedSanitizer.clean(fixture["html"], fixture["url"]) }

        it "is stable" do
          expect(EmbedSanitizer.clean(cleaned, fixture["url"])).to eq(cleaned)
        end
      end
    end
  end
end
