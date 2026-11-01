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
end
