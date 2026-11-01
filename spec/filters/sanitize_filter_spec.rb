# frozen_string_literal: true

require "rails_helper"

describe SanitizeFilter do
  subject(:output) { described_class.new(input).to_html }

  let(:sandbox) { 'sandbox="allow-scripts allow-same-origin allow-popups allow-presentation"' }
  let(:rel) { 'rel="nofollow noopener noreferrer ugc"' }

  context "when input contains a form tag" do
    let(:input) { '<form action="/" method="post"></form>' }

    it { is_expected.to eq("") }
  end

  context "when input contains UJS attributes" do
    let(:input) { '<a href="/" data-method="post" data-remote="true">foo</a>' }

    it { is_expected.to eq('<a href="/">foo</a>') }
  end

  context "when input contains data attributes that aren't allowed" do
    let(:input) { '<div data-controller="foo" data-oembed-url="https://example.com/">x</div>' }

    it { is_expected.to eq('<div data-oembed-url="https://example.com/">x</div>') }
  end

  context "when input contains embed provider markup" do
    let(:input) do
      '<blockquote class="mastodon-embed quote" data-embed-url="https://mastodon.social/@a/1/embed">a</blockquote>' \
        '<blockquote class="bluesky-embed" data-bluesky-uri="at://did:plc:x/post/1" ' \
        'data-bluesky-cid="x">b</blockquote>' \
        '<blockquote class="instagram-media" data-instgrm-permalink="https://www.instagram.com/p/1/" ' \
        'data-instgrm-version="14" data-instgrm-captioned>c</blockquote>' \
        '<div class="fb-post" data-href="https://www.facebook.com/x" data-width="500" fb-xfbml-state="x">' \
        '<blockquote class="fb-xfbml-parse-ignore">d</blockquote></div>' \
        '<div class="tumblr-post" data-href="https://embed.tumblr.com/x" data-did="x">e</div>' \
        '<blockquote class="imgur-embed-pub" data-id="a/1" data-context="false">f</blockquote>' \
        '<iframe class="mastodon-embed" src="https://mastodon.social/@a/1/embed"></iframe>' \
        '<div class="fb-video">g</div>'
    end
    let(:output_html) do
      '<blockquote class="quote">a</blockquote><blockquote>b</blockquote><blockquote>c</blockquote>' \
        "<div><blockquote>d</blockquote></div><div>e</div><blockquote>f</blockquote>" \
        '<iframe src="https://mastodon.social/@a/1/embed" ' \
        "#{sandbox}></iframe><div>g</div>"
    end

    it { is_expected.to eq(output_html) }
  end

  context "when input contains an applet tag" do
    let(:input) { '<applet code="wtf.class">wtf</applet>' }

    it { is_expected.to eq("wtf") }
  end

  context "when input contains a picture element" do
    let(:input) do
      '<picture><source type="image/webp" srcset="/a.webp 400w, /b.webp 800w">' \
        '<img src="/a.png" width="400" height="300" data-full-src="/c.png"></picture>'
    end

    it { is_expected.to eq(input) }
  end

  context "when input contains a srcset with an unsafe candidate" do
    let(:input) { '<img src="/a.png" srcset="/a.png 1x, javascript:alert(1) 2x">' }

    it { is_expected.to eq('<img src="/a.png">') }
  end

  context "when input contains syntax highlighted code" do
    let(:input) do
      '<div class="highlight"><pre class="highlight"><code>' \
        '<span class="nb">puts</span></code></pre></div>'
    end

    it { is_expected.to eq(input) }
  end

  context "when input contains a spoiler" do
    let(:input) { '<div class="spoiler"><p>secret</p></div>' }

    it { is_expected.to eq(input) }
  end

  context "when input contains a quote" do
    let(:input) { "<blockquote><cite>Someone</cite><p>Quote</p></blockquote>" }

    it { is_expected.to eq(input) }
  end

  context "when input contains a table" do
    let(:input) do
      '<table border="1"><thead><tr><th colspan="2">a</th></tr></thead>' \
        '<tbody><tr><td align="right">b</td><td>c</td></tr></tbody></table>'
    end

    it { is_expected.to eq(input) }
  end

  context "when input contains an oEmbed placeholder" do
    let(:input) do
      '<div class="embed" data-oembed-url="https://vimeo.com/1">' \
        '<a href="https://vimeo.com/1">https://vimeo.com/1</a></div>'
    end

    it { is_expected.to eq(input.sub("<a href=\"https://vimeo.com/1\"", "<a href=\"https://vimeo.com/1\" #{rel}")) }
  end

  context "when input contains a YouTube placeholder" do
    let(:input) { '<div class="youtube-embed" data-youtube-id="abcd" data-youtube-title="title"></div>' }

    it { is_expected.to eq(input) }
  end

  context "when the oEmbed placeholder has an unsafe URL" do
    let(:input) { '<div class="embed" data-oembed-url="javascript:alert(1)"></div>' }

    it { is_expected.to eq('<div class="embed"></div>') }
  end

  context "when input contains a style attribute" do
    let(:input) { '<div style="color: red; behavior: url(x.htc); background: url(javascript:alert(1))">x</div>' }

    it { is_expected.to eq('<div style="color: red;  ">x</div>') }
  end

  context "when input contains a mailto link" do
    let(:input) { '<a href="mailto:foo@example.com">foo</a>' }

    it { is_expected.to eq("<a href=\"mailto:foo@example.com\" #{rel}>foo</a>") }
  end

  context "when input contains an external link" do
    let(:input) { '<a href="https://example.com/" rel="me" target="_blank">foo</a>' }

    it { is_expected.to eq("<a href=\"https://example.com/\" #{rel} target=\"_blank\">foo</a>") }
  end

  context "when input contains a protocol-relative link" do
    let(:input) { '<a href="//example.com/">foo</a>' }

    it { is_expected.to eq("<a href=\"//example.com/\" #{rel}>foo</a>") }
  end

  context "when input contains a relative link" do
    let(:input) { '<a href="/discussions/1#post-2" rel="nofollow">foo</a>' }

    it { is_expected.to eq('<a href="/discussions/1#post-2">foo</a>') }
  end

  context "when input contains a link with an unsupported scheme" do
    let(:input) { '<a href="ftp://example.com/file">foo</a>' }

    it { is_expected.to eq("<a>foo</a>") }
  end

  context "when input contains a data URI image" do
    let(:input) { '<img src="data:image/png;base64,iVBORw0KGgo=">' }

    it { is_expected.to eq(input) }
  end

  context "when input contains a data URI image over 100 kB" do
    let(:input) { "<img src=\"data:image/png;base64,#{'A' * 100_000}\">" }

    it { is_expected.to eq("<img>") }
  end

  context "when input contains a data URI image just under 100 kB" do
    let(:input) { "<img src=\"data:image/png;base64,#{'A' * 99_900}\">" }

    it { is_expected.to eq(input) }
  end

  context "when input contains a data URI SVG image" do
    let(:input) { '<img src="data:image/svg+xml;base64,PHN2Zz4=">' }

    it { is_expected.to eq("<img>") }
  end

  context "when input contains an iframe" do
    let(:input) do
      '<iframe src="https://www.youtube.com/embed/abcd" width="560" height="315" ' \
        'frameborder="0" allow="autoplay; camera; encrypted-media" allowfullscreen></iframe>'
    end
    let(:output_html) do
      '<iframe src="https://www.youtube.com/embed/abcd" width="560" height="315" ' \
        'frameborder="0" allow="autoplay; encrypted-media" allowfullscreen="" ' \
        "#{sandbox}></iframe>"
    end

    it { is_expected.to eq(output_html) }
  end

  context "when input contains an iframe with a protocol-relative URL" do
    let(:input) { '<iframe src="//www.youtube.com/embed/abcd"></iframe>' }

    it { is_expected.to eq("<iframe src=\"https://www.youtube.com/embed/abcd\" #{sandbox}></iframe>") }
  end

  context "when input contains an iframe with a plain HTTP URL" do
    let(:input) { '<iframe src="http://example.com/"></iframe>' }

    it { is_expected.to eq("<iframe #{sandbox}></iframe>") }
  end

  context "when input contains an iframe with a relative URL" do
    let(:input) { '<iframe src="/admin"></iframe>' }

    it { is_expected.to eq("<iframe #{sandbox}></iframe>") }
  end

  context "when input contains an iframe with its own sandbox" do
    let(:input) do
      '<iframe src="https://www.youtube.com/embed/abcd" ' \
        'sandbox="allow-scripts allow-same-origin allow-top-navigation allow-modals"></iframe>'
    end

    it { is_expected.to eq("<iframe src=\"https://www.youtube.com/embed/abcd\" #{sandbox}></iframe>") }
  end

  context "when input contains fixed positioning" do
    let(:input) do
      '<div style="position: fixed; top: 0; color: red">a</div>' \
        '<div style="POSITION:Sticky">b</div>' \
        '<div style="position: f\\69xed !important">c</div>' \
        '<div style="position: -webkit-sticky">d</div>' \
        '<div style="position: var(--x)">e</div>'
    end

    it "removes it" do
      expect(output).not_to match(/position/i)
    end
  end

  context "when input contains relative positioning" do
    let(:input) { '<div style="position: relative; top: 2px">a</div>' }

    it { is_expected.to eq(input) }
  end

  context "when input contains an id attribute" do
    let(:input) { '<p id="main" name="x">foo</p>' }

    it { is_expected.to eq("<p>foo</p>") }
  end

  SCRIPT_VECTORS.each do |description, html|
    context "when input contains #{description}" do
      let(:input) { html }

      it { is_expected.to be_free_of_script_vectors }
    end
  end

  describe "allowlists" do
    excluded = %w[svg math noscript template style script object embed]

    [SanitizeFilter::CONFIG, EmbedSanitizer::CONFIG].each do |config|
      excluded.each do |element|
        it "doesn't allow #{element}" do
          expect(config[:elements]).not_to include(element)
        end
      end
    end
  end
end
