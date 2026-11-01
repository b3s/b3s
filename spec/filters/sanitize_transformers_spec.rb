# frozen_string_literal: true

require "rails_helper"

describe SanitizeTransformers do
  describe ".external_link_rel" do
    subject(:output) { Sanitize.fragment(input, config) }

    let(:config) do
      { elements: %w[a], attributes: { "a" => %w[href rel] }, transformers: [described_class.external_link_rel] }
    end

    context "when the config has no href protocols" do
      let(:input) { '<a href="https://example.com/">foo</a>' }

      it { is_expected.to eq('<a href="https://example.com/" rel="nofollow noopener noreferrer ugc">foo</a>') }
    end

    context "when the config has no href protocols and the link is relative" do
      let(:input) { '<a href="/foo" rel="me">foo</a>' }

      it { is_expected.to eq('<a href="/foo">foo</a>') }
    end
  end
end
