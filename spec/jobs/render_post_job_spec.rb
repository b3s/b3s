# frozen_string_literal: true

require "rails_helper"

RSpec.describe RenderPostJob do
  subject(:perform) { described_class.perform_now(post.id) }

  let(:url) { "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }
  let(:link) { "<a href=\"#{url}\" rel=\"nofollow noopener noreferrer ugc\">#{url}</a>" }
  let(:oembed) { stub_request(:get, %r{\Ahttps://www\.youtube\.com/oembed}) }
  let(:post) do
    create(:post, format: "html", skip_preprocess: true, body_html: "stale",
                  body: '<embed src="http://www.youtube.com/v/dQw4w9WgXcQ" type="application/x-shockwave-flash">')
  end

  before do
    dns = instance_double(Resolv::DNS, :timeouts= => nil)
    allow(dns).to receive(:getaddresses).and_return([Resolv::IPv4.create("93.184.215.14")])
    allow(Resolv::DNS).to receive(:new).and_return(dns)
  end

  context "when the embed can be fetched" do
    before do
      oembed.to_return(body: { type: "video", version: "1.0",
                               html: '<iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ"></iframe>' }.to_json)
    end

    it "renders the embed" do
      perform
      expect(post.reload.body_html).to include('src="https://www.youtube.com/embed/dQw4w9WgXcQ"')
    end

    it "touches the exchange" do
      expect { Timecop.freeze(1.hour.from_now) { perform } }.to(change { post.exchange.reload.updated_at })
    end

    it "keeps the edit timestamp" do
      expect { perform }.not_to(change { post.reload.edited_at })
    end
  end

  context "when the embed is gone" do
    before { oembed.to_return(status: 404) }

    it "renders a link" do
      perform
      expect(post.reload.body_html).to eq(link)
    end
  end

  context "when the fetch fails temporarily" do
    before { oembed.to_return(status: 503) }

    it "keeps the stale HTML" do
      perform
      expect(post.reload.body_html).to eq("stale")
    end

    it "retries" do
      perform
      expect(described_class).to have_been_enqueued.with(post.id)
    end
  end

  context "when the fetch keeps failing", :cache do
    before { oembed.to_return(status: 503) }

    it "renders a link after the last attempt" do
      perform_enqueued_jobs { described_class.perform_later(post.id) }
      expect(post.reload.body_html).to eq(link)
    end

    it "gives up after fifteen attempts" do
      perform_enqueued_jobs { described_class.perform_later(post.id) }
      expect(oembed).to have_been_requested.times(15)
    end
  end

  context "when the post is edited during the render" do
    before do
      oembed.to_return do
        Post.find(post.id).update!(body: "edited")
        { status: 404 }
      end
    end

    it "keeps the edited HTML" do
      perform
      expect(post.reload.body_html).to include("edited")
    end
  end

  context "when the post doesn't exist" do
    subject(:perform) { described_class.perform_now(999_999) }

    it { expect { perform }.not_to raise_error }
  end
end
