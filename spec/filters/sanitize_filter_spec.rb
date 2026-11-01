# frozen_string_literal: true

require "rails_helper"

describe SanitizeFilter do
  subject(:output) { described_class.new(input).to_html }

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
        '<iframe src="https://mastodon.social/@a/1/embed"></iframe><div>g</div>'
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

    it { is_expected.to eq(input) }
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

    it { is_expected.to eq(input) }
  end

  context "when input contains a relative link" do
    let(:input) { '<a href="/discussions/1#post-2">foo</a>' }

    it { is_expected.to eq(input) }
  end

  context "when input contains a link with an unsupported scheme" do
    let(:input) { '<a href="ftp://example.com/file">foo</a>' }

    it { is_expected.to eq("<a>foo</a>") }
  end

  context "when input contains a data URI image" do
    let(:input) { '<img src="data:image/png;base64,iVBORw0KGgo=">' }

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
        'frameborder="0" allow="autoplay; encrypted-media" allowfullscreen=""></iframe>'
    end

    it { is_expected.to eq(output_html) }
  end

  context "when input contains an iframe with a protocol-relative URL" do
    let(:input) { '<iframe src="//www.youtube.com/embed/abcd"></iframe>' }

    it { is_expected.to eq('<iframe src="https://www.youtube.com/embed/abcd"></iframe>') }
  end

  context "when input contains an iframe with a plain HTTP URL" do
    let(:input) { '<iframe src="http://example.com/"></iframe>' }

    it { is_expected.to eq("<iframe></iframe>") }
  end

  context "when input contains an iframe with a relative URL" do
    let(:input) { '<iframe src="/admin"></iframe>' }

    it { is_expected.to eq("<iframe></iframe>") }
  end

  context "when input contains an id attribute" do
    let(:input) { '<p id="main" name="x">foo</p>' }

    it { is_expected.to eq("<p>foo</p>") }
  end

  {
    "a script tag" => "<script>alert('foo');</script>",
    "a mixed case script tag" => "<ScRiPt>alert(1)</sCrIpT>",
    "a script tag inside svg" => "<svg><script>alert(document.domain)</script></svg>",
    "a script tag inside math" => "<math><mi><script>alert(1)</script></mi></math>",
    "an svg animate setting href" =>
      '<svg><a><animate attributeName="href" values="0;javascript:alert(1)"/>' \
      '<text x="20" y="20">x</text></a></svg>',
    "an svg link with xlink:href" =>
      '<svg><a xlink:href="javascript:alert(1)"><text>x</text></a></svg>',
    "an svg with onload" => '<svg onload="alert(1)">',
    "math with an href" => '<math href="javascript:alert(1)"><mi>x</mi></math>',
    "an iframe with srcdoc" =>
      '<iframe srcdoc="&lt;script&gt;alert(1)&lt;/script&gt;"></iframe>',
    "an iframe with a data URI" =>
      '<iframe src="data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;"></iframe>',
    "an iframe with a javascript URL" => '<iframe src="javascript:alert(1)"></iframe>',
    "a javascript URL" => "<a href=\"javascript:alert('hi');\">link</a>",
    "a mixed case javascript URL" => '<a href="JaVaScRiPt:alert(1)">link</a>',
    "a javascript URL with an encoded tab" => '<a href="java&#9;script:alert(1)">link</a>',
    "a javascript URL with an encoded newline" => '<a href="java&#x0A;script:alert(1)">link</a>',
    "a javascript URL with a literal tab" => "<a href=\"java\tscript:alert(1)\">link</a>",
    "a javascript URL with leading control characters" =>
      '<a href="&#1;&#31; javascript:alert(1)">link</a>',
    "a javascript URL with an encoded colon" => '<a href="javascript&colon;alert(1)">link</a>',
    "a javascript URL with encoded letters" =>
      '<a href="&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;alert(1)">link</a>',
    "a javascript URL with unterminated entities" =>
      '<a href="&#0000106&#0000097vascript:alert(1)">link</a>',
    "a vbscript URL" => '<a href="vbscript:msgbox(1)">link</a>',
    "a data URL link" => '<a href="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==">link</a>',
    "a javascript image source" => '<img src="javascript:alert(1)">',
    "an event handler" => "<img src=\"image.jpg\" onload=\"alert('hi');\">",
    "a mixed case event handler" => '<img src="x" OnErRoR="alert(1)">',
    "a formaction attribute" =>
      '<form><button formaction="javascript:alert(1)">x</button></form>',
    "a button with formaction" => '<button formaction="javascript:alert(1)">x</button>',
    "an input with formaction" => '<input type="image" formaction="javascript:alert(1)">',
    "a base tag" => '<base href="javascript:alert(1)//">',
    "a meta refresh" => '<meta http-equiv="refresh" content="0;url=javascript:alert(1)">',
    "a link tag" => '<link rel="stylesheet" href="theme.css">',
    "a style tag" => "<style>@import 'javascript:alert(1)'; body { background: red }</style>",
    "a style tag inside svg" => "<svg><style>*{x:expression(alert(1))}</style></svg>",
    "an object tag" => '<object data="javascript:alert(1)"></object>',
    "an embed tag" => '<embed src="javascript:alert(1)">',
    "a noscript tag" => '<noscript><p title="</noscript><img src=x onerror=alert(1)>"></noscript>',
    "a template tag" => "<template><script>alert(1)</script></template>",
    "a video poster" => '<video poster="javascript:alert(1)"></video>',
    "a blockquote cite" => '<blockquote cite="javascript:alert(1)">x</blockquote>',
    "a comment breaking out" => "<!--><script>alert(1)</script>-->",
    "a mangled script tag" => "<scr<script>ipt>alert(1)</script>",
    "a script with a slash" => "<script/x>alert(1)</script>"
  }.each do |description, html|
    context "when input contains #{description}" do
      let(:input) { html }

      it { is_expected.to be_free_of_script_vectors }
    end
  end
end
