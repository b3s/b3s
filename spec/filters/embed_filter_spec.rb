# frozen_string_literal: true

require "rails_helper"

describe EmbedFilter do
  subject(:rendered) { described_class.new(input).to_html }

  before do
    dns = instance_double(Resolv::DNS, :timeouts= => nil)
    allow(dns).to receive(:getaddresses).and_return([Resolv::IPv4.create("93.184.215.14")])
    allow(Resolv::DNS).to receive(:new).and_return(dns)
  end

  def placeholder(url, content = "<a href=\"#{url}\">#{url}</a>")
    "<div class=\"embed\" data-oembed-url=\"#{url}\">#{content}</div>"
  end

  def fixture(name)
    JSON.parse(Rails.root.join("spec/support/requests/oembed/#{name}.json").read)
  end

  def parsed
    Nokogiri::HTML5::DocumentFragment.parse(rendered)
  end

  shared_examples "a cleaned embed" do |selector|
    it { is_expected.to be_free_of_script_vectors }

    it "keeps the embed markup inside the placeholder" do
      expect(parsed.css("div.embed[data-oembed-url] #{selector}")).to be_present
    end
  end

  %w[bluesky flickr giphy imgur mastodon soundcloud spotify tidal tiktok
     tumblr vimeo youtube].each do |name|
    context "when the embed is a cached #{name} response" do
      let(:input) { placeholder(fixture(name)["url"]) }

      before { OembedResponse.store(fixture(name)["url"], fixture(name)["html"]) }

      it { is_expected.to be_free_of_script_vectors }

      it "expands the embed" do
        expect(parsed.at_css("div.embed").children).to be_present
      end
    end
  end

  context "when the embed is from Bluesky" do
    let(:input) { placeholder(fixture("bluesky")["url"]) }

    before { OembedResponse.store(fixture("bluesky")["url"], fixture("bluesky")["html"]) }

    it_behaves_like "a cleaned embed",
                    "blockquote.bluesky-embed[data-bluesky-uri^='at://'][data-bluesky-cid] p"
  end

  context "when the embed is from Mastodon" do
    let(:input) { placeholder(fixture("mastodon")["url"]) }

    before { OembedResponse.store(fixture("mastodon")["url"], fixture("mastodon")["html"]) }

    it_behaves_like "a cleaned embed",
                    "blockquote.mastodon-embed" \
                    "[data-embed-url='https://mastodon.social/@ghorwood/110149321725092169/embed'] a"

    it "strips inline styles" do
      expect(parsed.css("[style]")).to be_empty
    end

    it "strips the svg" do
      expect(rendered).not_to include("<svg")
    end
  end

  context "when the embed is from Imgur" do
    let(:input) { placeholder(fixture("imgur")["url"]) }

    before { OembedResponse.store(fixture("imgur")["url"], fixture("imgur")["html"]) }

    it_behaves_like "a cleaned embed", "blockquote.imgur-embed-pub[lang='en'][data-id='a/Pdy2vBa'] a"
  end

  context "when the embed is from Tumblr" do
    let(:input) { placeholder(fixture("tumblr")["url"]) }

    before { OembedResponse.store(fixture("tumblr")["url"], fixture("tumblr")["html"]) }

    it_behaves_like "a cleaned embed", "div.tumblr-post[data-href^='https://embed.tumblr.com/'][data-did] a"
  end

  context "when the embed is from Instagram" do
    let(:url) { "https://www.instagram.com/p/8ql-VChPSZ/" }
    let(:input) { placeholder(url) }
    let(:html) do
      '<blockquote class="instagram-media" data-instgrm-captioned ' \
        "data-instgrm-permalink=\"#{url}\" data-instgrm-version=\"14\" style=\"background:#FFF\">" \
        "<a href=\"#{url}\">View this post on Instagram</a></blockquote>" \
        '<script async src="//www.instagram.com/embed.js"></script>'
    end

    before { OembedResponse.store(url, html) }

    it_behaves_like "a cleaned embed",
                    "blockquote.instagram-media[data-instgrm-captioned][data-instgrm-version='14']" \
                    "[data-instgrm-permalink='https://www.instagram.com/p/8ql-VChPSZ/'] a"
  end

  context "when the embed is a Facebook video" do
    let(:url) { "https://www.facebook.com/facebook/videos/10153231379946729/" }
    let(:input) { placeholder(url) }
    let(:html) do
      '<div id="fb-root"></div><script async defer src="https://connect.facebook.net/en_US/sdk.js"></script>' \
        "<div class=\"fb-video\" data-href=\"#{url}\" data-width=\"500\">" \
        "<blockquote cite=\"#{url}\" class=\"fb-xfbml-parse-ignore\"><a href=\"#{url}\">Video</a>" \
        "</blockquote></div>"
    end

    before { OembedResponse.store(url, html) }

    it_behaves_like "a cleaned embed",
                    "div.fb-video[data-href='https://www.facebook.com/facebook/videos/10153231379946729/']" \
                    "[data-width='500'] blockquote.fb-xfbml-parse-ignore[cite]"

    it "drops the id" do
      expect(parsed.css("#fb-root")).to be_empty
    end
  end

  context "when the embed is from Spotify" do
    let(:input) { placeholder(fixture("spotify")["url"]) }

    before { OembedResponse.store(fixture("spotify")["url"], fixture("spotify")["html"]) }

    it "keeps the iframe style" do
      expect(parsed.at_css("iframe")["style"]).to eq("border-radius: 12px")
    end
  end

  context "when the embed is from Tidal" do
    let(:input) { placeholder(fixture("tidal")["url"]) }

    before { OembedResponse.store(fixture("tidal")["url"], fixture("tidal")["html"]) }

    it "keeps the allowed iframe permissions" do
      expect(parsed.at_css("iframe")["allow"])
        .to eq("encrypted-media; fullscreen; clipboard-write https://embed.tidal.com; web-share")
    end
  end

  {
    "youtube" => "www.youtube.com",
    "vimeo" => "player.vimeo.com",
    "spotify" => "open.spotify.com",
    "soundcloud" => "w.soundcloud.com",
    "tidal" => "embed.tidal.com",
    "tiktok" => "www.tiktok.com"
  }.each do |name, host|
    context "when the #{name} embed has an iframe" do
      let(:input) { placeholder(fixture(name)["url"]) }

      before { OembedResponse.store(fixture(name)["url"], fixture(name)["html"]) }

      it "keeps the iframe on #{host}" do
        expect(parsed.css("iframe").map { |iframe| URI.parse(iframe["src"]).host }).to eq([host])
      end
    end
  end

  {
    "https://www.youtube.com/watch?v=abcd" => %w[www.youtube.com youtube.com www.youtube-nocookie.com],
    "https://vimeo.com/1" => %w[player.vimeo.com],
    "https://giphy.com/gifs/x" => %w[giphy.com],
    "https://www.kickstarter.com/projects/a/b" => %w[www.kickstarter.com],
    "https://codepen.io/a/pen/b" => %w[codepen.io],
    "https://hachyderm.io/@a/1" => %w[hachyderm.io],
    "https://bsky.app/profile/a/post/b" => [],
    "https://imgur.com/gallery/a" => [],
    "https://example.com/" => []
  }.each do |url, hosts|
    context "when the provider for #{url} is matched" do
      subject { EmbedSanitizer.iframe_hosts(url) }

      it { is_expected.to eq(hosts) }
    end
  end

  context "when an embed has iframes on other hosts" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }
    let(:html) do
      '<iframe src="https://player.vimeo.com/video/1"></iframe>' \
        '<iframe src="https://www.youtube.com/embed/x"></iframe>' \
        '<iframe src="https://evil.example/"></iframe>' \
        '<iframe src="https://player.vimeo.com.evil.example/"></iframe>'
    end

    before { OembedResponse.store(url, html) }

    it "drops them" do
      expect(parsed.css("iframe").pluck("src")).to eq(["https://player.vimeo.com/video/1"])
    end
  end

  context "when an embed iframe host differs in case" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }

    before { OembedResponse.store(url, '<iframe src="https://Player.VIMEO.com/video/1"></iframe>') }

    it "keeps it" do
      expect(parsed.css("iframe").pluck("src")).to eq(["https://Player.VIMEO.com/video/1"])
    end
  end

  {
    "userinfo" => "https://player.vimeo.com@evil.example/video/1",
    "a backslash" => "https://evil.example\\@player.vimeo.com/video/1",
    "a fragment with @" => 'https://evil.example#@player.vimeo.com/video/1',
    "a percent-encoded host" => "https://player%2Evimeo%2Ecom/video/1",
    "a port" => "https://player.vimeo.com:8443/video/1"
  }.each do |description, src|
    context "when an embed iframe src has #{description}" do
      let(:url) { "https://vimeo.com/1" }
      let(:input) { placeholder(url) }

      before { OembedResponse.store(url, "<p>x</p><iframe src=\"#{src}\"></iframe>") }

      it "removes the iframe" do
        expect(parsed.css("iframe")).to be_empty
      end
    end
  end

  context "when a Mastodon embed has a legacy iframe" do
    let(:url) { "https://hachyderm.io/@a/1" }
    let(:input) { placeholder(url) }
    let(:html) do
      '<iframe class="mastodon-embed" src="https://hachyderm.io/@a/1/embed"></iframe>' \
        '<iframe class="mastodon-embed" src="https://mastodon.social/@a/1/embed"></iframe>'
    end

    before { OembedResponse.store(url, html) }

    it "keeps only the iframe on the matched instance" do
      expect(parsed.css("iframe.mastodon-embed").pluck("src")).to eq(["https://hachyderm.io/@a/1/embed"])
    end
  end

  context "when the cached HTML is hostile" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }
    let(:html) do
      "<script>alert(1)</script>" \
        "<svg><script>alert(1)</script></svg>" \
        '<p onclick="alert(1)" style="position:fixed">Title</p>' \
        '<a href="javascript:alert(1)">bad</a>' \
        '<a href="java&#9;script:alert(1)">bad</a>' \
        '<iframe src="http://player.vimeo.com/video/1"></iframe>' \
        '<iframe srcdoc="&lt;script&gt;alert(1)&lt;/script&gt;"></iframe>' \
        '<iframe src="https://player.vimeo.com/video/1" onload="alert(1)" allow="camera; autoplay"></iframe>' \
        '<img src="http://example.com/a.png"><form><input></form><style>*{}</style>' \
        '<div class="embed" data-oembed-url="https://vimeo.com/2">nested</div>'
    end

    before { OembedResponse.store(url, html) }

    it { is_expected.to be_free_of_script_vectors }

    it "strips styles outside iframes" do
      expect(parsed.css("p[style]")).to be_empty
    end

    it "drops iframe sources that aren't https" do
      expect(parsed.css("iframe").pluck("src").compact).to eq(["https://player.vimeo.com/video/1"])
    end

    it "restricts iframe permissions" do
      expect(parsed.css("iframe[allow]").pluck("allow")).to eq(["autoplay"])
    end

    it "drops images that aren't https" do
      expect(parsed.css("img[src]")).to be_empty
    end

    it "drops data attributes it doesn't know" do
      expect(parsed.css("[data-oembed-url]").pluck("data-oembed-url")).to eq([url])
    end
  end

  context "when the cached HTML has provider attributes for the wrong hosts" do
    let(:url) { "https://mastodon.social/@foo/1" }
    let(:input) { placeholder(url) }
    let(:html) do
      '<blockquote class="mastodon-embed" data-embed-url="https://evil.example/@foo/1/embed">a</blockquote>' \
        '<blockquote class="mastodon-embed" data-embed-url="https://mastodon.social/@foo/1">b</blockquote>' \
        '<blockquote class="mastodon-embed" data-embed-url="https://hachyderm.io/@foo/1/embed">b</blockquote>' \
        '<blockquote class="mastodon-embed" data-embed-url="https://mastodon.social:8443/@foo/1/embed">b</blockquote>' \
        '<blockquote class="mastodon-embed" data-embed-url="https://x@mastodon.social/@foo/1/embed">b</blockquote>' \
        '<blockquote class="instagram-media" data-instgrm-permalink="https://evil.example/p/1/">c</blockquote>' \
        '<blockquote class="bluesky-embed" data-bluesky-uri="javascript:alert(1)">d</blockquote>' \
        '<div class="tumblr-post" data-href="https://evil.example/embed">e</div>' \
        '<div class="fb-post" data-href="https://www.tumblr.com/post">f</div>' \
        '<div data-href="https://www.facebook.com/post">g</div>'
    end

    before { OembedResponse.store(url, html) }

    it "removes the attributes" do
      expect(parsed.css("[data-embed-url], [data-instgrm-permalink], [data-bluesky-uri], [data-href]"))
        .to be_empty
    end
  end

  context "when the cached HTML contains bidi control characters" do
    let(:url) { "https://www.flickr.com/photos/foo/1/" }
    let(:input) { placeholder(url) }
    let(:html) do
      "<a href=\"#{url}\" title=\"foo\u202Eoof\u2066bar\u2069\">" \
        "<img src=\"https://live.staticflickr.com/1.jpg\" alt=\"&#x202E;evil\"></a>\u202Dtext"
    end

    before { OembedResponse.store(url, html) }

    it "strips them" do
      expect(rendered).not_to match(/[\u202A-\u202E\u2066-\u2069]/)
    end
  end

  context "when the embed isn't cached" do
    let(:url) { "https://www.tumblr.com/staff/123456789" }
    let(:input) { placeholder("https://staff.tumblr.com/post/123456789") }
    let(:html) { '<div class="tumblr-post"><a href="https://staff.tumblr.com/post/1">x</a></div><script></script>' }
    let(:oembed_request) do
      stub_request(:get, "https://www.tumblr.com/oembed/1.0/")
        .with(query: { format: "json", url: "https://staff.tumblr.com/post/123456789" })
    end

    before do
      oembed_request.to_return(status: 200, body: { type: "rich", version: "1.0", html: }.to_json)
    end

    it "fetches it" do
      expect(rendered).to include('<div class="tumblr-post"><a href="https://staff.tumblr.com/post/1" ' \
                                  'rel="nofollow noopener noreferrer ugc">x</a></div>')
    end

    it { is_expected.to be_free_of_script_vectors }

    it "caches the provider response" do
      rendered
      expect(OembedResponse.find_by(url: "https://staff.tumblr.com/post/123456789").html).to eq(html)
    end

    it "builds the endpoint URL with the provider" do
      rendered
      expect(oembed_request).to have_been_made.once
    end

    it "does not log an error" do
      allow(Rails.logger).to receive(:error)
      rendered
      expect(Rails.logger).not_to have_received(:error)
    end

    it "relies on OEmbed::Provider#build being public" do
      expect(OEmbed::Provider.public_method_defined?(:build)).to be(true)
    end

    it "requests an unencoded response" do
      rendered
      expect(oembed_request.with(headers: { "Accept-Encoding" => "identity" })).to have_been_made.once
    end

    it "limits the fetch to seven seconds" do
      allow(Timeout).to receive(:timeout).and_call_original
      rendered
      expect(Timeout).to have_received(:timeout).with(7)
    end
  end

  context "when the provider redirects" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }
    let(:link) { "<a href=\"#{url}\" rel=\"nofollow noopener noreferrer ugc\">#{url}</a>" }
    let(:location) { "https://other.example.com/oembed" }

    before do
      allow(Resolv::DNS.new).to receive(:getaddresses).with("internal.example.com")
                                                      .and_return([Resolv::IPv4.create("10.0.0.1")])
      stub_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json})
        .to_return(status: 302, headers: { "Location" => location })
      stub_request(:get, location)
        .to_return(body: { type: "rich", version: "1.0", html: "<p>embed</p>" }.to_json)
    end

    context "when the redirect is to a public address" do
      it "follows it" do
        expect(rendered).to eq(placeholder(url, "<p>embed</p>"))
      end
    end

    context "when the redirect is to a loopback address" do
      let(:location) { "http://127.0.0.1/oembed" }

      it "falls back to a link" do
        expect(rendered).to eq(link)
      end

      it "does not follow the redirect" do
        rendered
        expect(a_request(:get, location)).not_to have_been_made
      end
    end

    context "when the redirect is to a link-local address" do
      let(:location) { "http://169.254.169.254/latest/meta-data/" }

      it "does not follow the redirect" do
        rendered
        expect(a_request(:get, location)).not_to have_been_made
      end
    end

    context "when the redirect is to a hostname resolving to a private address" do
      let(:location) { "http://internal.example.com/oembed" }

      it "falls back to a link" do
        expect(rendered).to eq(link)
      end

      it "does not follow the redirect" do
        rendered
        expect(a_request(:get, location)).not_to have_been_made
      end
    end
  end

  context "when the provider redirects too many times" do
    let(:input) { placeholder("https://vimeo.com/1") }

    before do
      stub_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json})
        .to_return(status: 302, headers: { "Location" => "https://other.example.com/0" })
      4.times do |i|
        stub_request(:get, "https://other.example.com/#{i}")
          .to_return(status: 302, headers: { "Location" => "https://other.example.com/#{i + 1}" })
      end
    end

    it "gives up after three redirects" do
      rendered
      expect(a_request(:get, %r{\Ahttps://other\.example\.com/})).to have_been_made.times(3)
    end
  end

  context "when the provider response contains non-ASCII text" do
    let(:input) { placeholder("https://vimeo.com/1") }

    before do
      stub_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json})
        .to_return(body: { type: "rich", version: "1.0", html: "<p>blåbærsyltetøy</p>" }.to_json)
    end

    it "keeps the text intact" do
      expect(rendered).to include("<p>blåbærsyltetøy</p>")
    end
  end

  context "when the provider response is too large" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }

    before do
      stub_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json})
        .to_return(body: { type: "rich", version: "1.0", html: "<p>#{'a' * 262_144}</p>" }.to_json)
    end

    it "falls back to a link" do
      expect(rendered).to eq("<a href=\"#{url}\" rel=\"nofollow noopener noreferrer ugc\">#{url}</a>")
    end
  end

  context "when a post has more embeds than the fetch limit" do
    let(:urls) { Array.new(26) { |i| "https://vimeo.com/#{i}" } }
    let(:input) { urls.map { |url| placeholder(url) }.join }

    before do
      stub_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json})
        .to_return(body: { type: "rich", version: "1.0", html: "<p>embed</p>" }.to_json)
    end

    it "stops fetching" do
      rendered
      expect(a_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json})).to have_been_made.times(25)
    end

    it "falls back to a link for the rest" do
      expect(rendered).to end_with("<a href=\"#{urls.last}\" rel=\"nofollow noopener noreferrer ugc\">#{urls.last}</a>")
    end

    it "does not cache the skipped embeds" do
      rendered
      expect(OembedResponse.exists?(url: urls.last)).to be(false)
    end

    it "does not count cached embeds" do
      urls.first(25).each { |url| OembedResponse.store(url, "<p>cached</p>") }
      expect(rendered).to end_with(placeholder(urls.last, "<p>embed</p>"))
    end
  end

  context "when fetching exceeds the render budget" do
    let(:clock) { { now: 0.0 } }
    let(:input) { Array.new(3) { |i| placeholder("https://vimeo.com/#{i}") }.join }

    before do
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC) { clock[:now] }
      stub_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json}).to_return do
        clock[:now] += 4
        { body: { type: "rich", version: "1.0", html: "<p>embed</p>" }.to_json }
      end
    end

    it "stops fetching" do
      rendered
      expect(a_request(:get, %r{\Ahttps://vimeo\.com/api/oembed\.json})).to have_been_made.twice
    end
  end

  context "when the fetch budget is already spent" do
    subject(:rendered) { described_class.new(input, fetch_budget:).to_html }

    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }
    let(:fetch_budget) { instance_double(FetchBudget, spend?: false) }

    before { stub_request(:any, //) }

    it "does not make a request" do
      rendered
      expect(a_request(:any, //)).not_to have_been_made
    end
  end

  context "when the embed is cached" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }

    before { OembedResponse.store(url, "<p>cached</p>") }

    it "uses the cached response" do
      expect(rendered).to eq(placeholder(url, "<p>cached</p>"))
    end

    it "doesn't make a request" do
      rendered
      expect(a_request(:any, //)).not_to have_been_made
    end
  end

  context "when the provider request fails" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }

    before { stub_request(:get, /vimeo\.com/).to_return(status: 500) }

    it "falls back to a link" do
      expect(rendered).to eq("<a href=\"#{url}\" rel=\"nofollow noopener noreferrer ugc\">#{url}</a>")
    end

    it "doesn't cache the response" do
      rendered
      expect(OembedResponse.exists?(url:)).to be(false)
    end

    it "doesn't retry within a day", :cache do
      rendered
      travel(23.hours) { described_class.new(input).to_html }
      expect(a_request(:get, /vimeo\.com/)).to have_been_made.once
    end

    it "retries after a day", :cache do
      rendered
      travel(25.hours) { described_class.new(input).to_html }
      expect(a_request(:get, /vimeo\.com/)).to have_been_made.twice
    end
  end

  context "when the cached HTML cleans up to nothing" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url) }

    before { OembedResponse.store(url, "<script>alert(1)</script>") }

    it "falls back to a link" do
      expect(rendered).to eq("<a href=\"#{url}\" rel=\"nofollow noopener noreferrer ugc\">#{url}</a>")
    end
  end

  context "when a placeholder is written by hand" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) { placeholder(url, '<blockquote class="spoiler">user content</blockquote>') }

    before { OembedResponse.store(url, "<p>embed</p>") }

    it "replaces the content with the embed" do
      expect(rendered).to eq(placeholder(url, "<p>embed</p>"))
    end
  end

  context "when a hand-written placeholder has an unregistered URL" do
    let(:url) { "https://example.com/" }
    let(:input) { placeholder(url, "<b>user content</b>") }

    it "turns it into a plain link" do
      expect(rendered).to eq("<a href=\"#{url}\" rel=\"nofollow noopener noreferrer ugc\">#{url}</a>")
    end

    it "doesn't make a request" do
      rendered
      expect(a_request(:any, //)).not_to have_been_made
    end
  end

  context "when placeholders are nested" do
    let(:url) { "https://vimeo.com/1" }
    let(:input) do
      placeholder(url, "#{placeholder('https://vimeo.com/2')}" \
                       '<div class="youtube-embed" data-youtube-id="abcd"></div>')
    end

    before { OembedResponse.store(url, "<p>embed</p>") }

    it "only expands the outer one" do
      expect(rendered).to eq(placeholder(url, "<p>embed</p>"))
    end
  end

  context "when input contains a YouTube placeholder" do
    let(:input) do
      '<div class="youtube-embed" data-youtube-id="ab_c-1" data-youtube-title="&quot;&gt;&lt;b&gt;">' \
        "<b>user content</b></div>"
    end
    let(:sandbox) do
      'sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-presentation ' \
        'allow-storage-access-by-user-activation"'
    end

    it "builds the iframe" do
      expect(rendered).to eq(
        '<iframe title="&quot;&gt;&lt;b&gt;" src="https://www.youtube.com/embed/ab_c-1" ' \
        "frameborder=\"0\" allowfullscreen=\"allowfullscreen\" #{sandbox}></iframe>"
      )
    end
  end

  context "when the YouTube placeholder has an invalid id" do
    let(:input) { '<div class="youtube-embed" data-youtube-id="../../evil?x=1">x</div>' }

    it { is_expected.to eq("") }
  end
end
