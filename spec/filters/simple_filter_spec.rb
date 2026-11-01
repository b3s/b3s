# frozen_string_literal: true

require "rails_helper"

describe SimpleFilter do
  let(:filter) { described_class.new(input) }

  it "strips surrounding whitespace" do
    expect(described_class.new("  \n\n  foo  \n\n  ").to_html).to eq("foo")
  end

  it "converts line breaks to <br>" do
    expect(described_class.new("foo\n\nbar").to_html).to(
      eq("foo<br>\n<br>\nbar")
    )
  end

  it "escapes left angle brackets" do
    expect(described_class.new("<3").to_html).to eq("&lt;3")
  end

  it "escapes right angle brackets" do
    expect(described_class.new(">:/").to_html).to eq("&gt;:/")
  end

  it "doesn't escape tags" do
    expect(
      described_class.new('<a href="#">link</a>').to_html
    ).to eq('<a href="#">link</a>')
  end

  it "doesn't escape right angle brackets after an empty attribute" do
    input = '<iframe src="//www.youtube.com/embed/Sq7XY_QRtzo" ' \
            "allowfullscreen></iframe>\nfoo"
    output = '<iframe src="//www.youtube.com/embed/Sq7XY_QRtzo" ' \
             "allowfullscreen=\"\"></iframe><br>\nfoo"
    expect(described_class.new(input).to_html).to eq(output)
  end

  context "when input contains a Markdown fenced code blocks" do
    let(:input) { "```ruby\nputs hello world\n```" }
    let(:parsed) { MarkdownFilter.new(input).to_html.strip }

    it "filters and base64 serialize the block" do
      expect(filter.to_html).to eq(parsed)
    end
  end
end
