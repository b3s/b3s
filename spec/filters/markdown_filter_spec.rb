# frozen_string_literal: true

require "rails_helper"

describe MarkdownFilter do
  let(:filter) { described_class.new(input) }

  context "when input contains a single line break" do
    let(:input) { "foo\nbar" }
    let(:output) { "<p>foo<br>\nbar</p>\n" }

    it "converts it to <br>" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains adjacent blockquotes" do
    let(:input) { "> quote 1\n\n  > quote 2" }
    let(:output) do
      "<blockquote>\n<p>quote 1</p>\n</blockquote>\n\n" \
        "<blockquote>\n<p>quote 2</p>\n</blockquote>\n"
    end

    it "converts it to <br>" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a spoiler tag" do
    let(:input) { '<div class="spoiler">*foo*</div>' }
    let(:output) { "<div class=\"spoiler\"><p><em>foo</em></p>\n</div>\n" }

    it "converts the contents of the spoiler tag from Markdown" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a YouTube code" do
    let(:id) { "abcd" }
    let(:output) do
      "<div class=\"youtube-embed\" data-youtube-id=\"#{id}\" " \
        "data-youtube-title=\"title\"></div>\n"
    end

    context "when URL is a short URL" do
      let(:input) { "!y[title](https://youtu.be/#{id})" }

      it "converts it to an embed placeholder" do
        expect(filter.to_html).to eq(output)
      end
    end

    context "when URL is a long URL" do
      let(:input) { "!y[title](https://www.youtube.com/watch?v=#{id})" }

      it "converts it to an embed placeholder" do
        expect(filter.to_html).to eq(output)
      end
    end

    context "when the title contains HTML" do
      let(:input) { "!y[\"><script>alert(1)</script>](https://youtu.be/#{id})" }

      it "escapes the title" do
        expect(filter.to_html).to include(
          'data-youtube-title="&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;"'
        )
      end
    end

    context "when the URL isn't a YouTube URL" do
      let(:input) { "!y[title](https://example.com/)" }

      it "leaves the code alone" do
        expect(filter.to_html).not_to include("youtube-embed")
      end
    end
  end
end
