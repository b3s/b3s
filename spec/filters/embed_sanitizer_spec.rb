# frozen_string_literal: true

require "rails_helper"

describe EmbedSanitizer do
  describe ".clean" do
    subject(:output) { described_class.clean(input, "https://www.facebook.com/x") }

    ["java\tscript:alert(1)", "java\nscript:alert(1)", "jav&#x09;ascript:alert(1)"].each do |url|
      context "when data-href is #{url.inspect}" do
        let(:input) { "<div class=\"fb-post\" data-href=\"#{url}\">x</div>" }

        it { is_expected.to eq('<div class="fb-post">x</div>') }
      end
    end

    context "when data-href has a tab in the scheme" do
      let(:input) { "<div class=\"fb-post\" data-href=\"ht\ttps://www.facebook.com/x\">x</div>" }

      it { is_expected.to eq('<div class="fb-post" data-href="https://www.facebook.com/x">x</div>') }
    end
  end

  describe ".clean with a provider iframe" do
    subject(:output) { described_class.clean(input, "https://vimeo.com/1") }

    let(:sandbox) do
      'sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-presentation"'
    end

    context "when the iframe has no sandbox" do
      let(:input) { '<iframe src="https://player.vimeo.com/video/1"></iframe>' }

      it { is_expected.to eq("<iframe src=\"https://player.vimeo.com/video/1\" #{sandbox}></iframe>") }
    end

    context "when the iframe has its own sandbox" do
      let(:input) do
        '<iframe src="https://player.vimeo.com/video/1" ' \
          'sandbox="allow-scripts allow-same-origin allow-top-navigation allow-forms"></iframe>'
      end

      it { is_expected.to eq("<iframe src=\"https://player.vimeo.com/video/1\" #{sandbox}></iframe>") }
    end
  end
end
