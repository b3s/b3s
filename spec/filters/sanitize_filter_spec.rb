# frozen_string_literal: true

require "rails_helper"

describe SanitizeFilter do
  let(:filter) { described_class.new(input) }

  context "when input contains a form tag" do
    let(:input) { '<form action="/" method="post"></form>' }

    it "strips the tag" do
      expect(filter.to_html).to eq("")
    end
  end

  context "when input contains UJS attributes" do
    let(:input) { '<a href="/" data-method="post">foo</a>' }

    it "strips the tag" do
      expect(filter.to_html).to eq('<a href="/">foo</a>')
    end
  end

  context "when input contains a script tag" do
    let(:input) { "<script>alert('foo');</script>" }

    it "strips the tag" do
      expect(filter.to_html).to eq("")
    end
  end

  context "when input contains an applet tag" do
    let(:input) { '<applet code="wtf.class">wtf</applet>' }

    it "strips the tag" do
      expect(filter.to_html).to eq("")
    end
  end

  context "when input contains an base tag" do
    let(:input) { '<base href="http://example.com/">' }

    it "strips the tag" do
      expect(filter.to_html).to eq("")
    end
  end

  context "when input contains a meta tag" do
    let(:input) { '<meta name="foo" content="bar">' }

    it "strips the tag" do
      expect(filter.to_html).to eq("")
    end
  end

  context "when input contains a link tag" do
    let(:input) { '<link rel="stylesheet" href="theme.css">' }

    it "strips the tag" do
      expect(filter.to_html).to eq("")
    end
  end

  context "when input contains a javascript: URL attribute" do
    let(:input) { "<a href=\"javascript:alert('hi');\">link</a>" }
    let(:output) { "<a>link</a>" }

    it "strips the attribute" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a javascript event handler" do
    let(:input) { "<img src=\"image.jpg\" onload=\"alert('hi');\">" }
    let(:output) { '<img src="image.jpg">' }

    it "strips the attribute" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains an element with allowScriptAccess" do
    let(:input) do
      '<iframe src="/foo" allowscriptaccess="always"></iframe>'
    end
    let(:output) do
      '<iframe src="/foo" allowscriptaccess="sameDomain"></iframe>'
    end

    it "sets it to sameDomain" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains an embed without allowScriptAccess" do
    let(:input) do
      '<embed src="/foo"></embed>'
    end
    let(:output) do
      '<embed src="/foo" allowScriptAccess="sameDomain">'
    end

    it "enforces the attribute" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a param called allowScriptAccess" do
    let(:input) do
      '<param name="allowScriptAccess" value="always">'
    end
    let(:output) do
      '<param name="allowScriptAccess" value="sameDomain">'
    end

    it "sets the value to sameDomain" do
      expect(filter.to_html).to eq(output)
    end
  end

  context "when input contains a picture element" do
    let(:input) do
      '<picture><source type="image/webp" srcset="/a.webp 400w">' \
        '<img src="/a.png" width="400" height="300"></picture>'
    end

    it "keeps the source and the fallback as siblings" do
      expect(filter.to_html).to eq(input)
    end
  end

  context "when input contains an object tag" do
    context "when the object doesn't have an allowScriptAccess param" do
      let(:input) do
        '<object data="foo.swf"></object>'
      end
      let(:output) do
        '<object data="foo.swf">' \
          '<param name="allowScriptAccess" value="sameDomain">' \
          "</object>"
      end

      it "add the param" do
        expect(filter.to_html).to eq(output)
      end
    end

    context "when the object has an allowScriptAccess param" do
      let(:input) do
        '<object data="foo.swf">' \
          '<param name="allowScriptAccess" value="always">' \
          "</object>"
      end
      let(:output) do
        '<object data="foo.swf">' \
          '<param name="allowScriptAccess" value="sameDomain">' \
          "</object>"
      end

      it "does not add an extra param" do
        expect(filter.to_html).to eq(output)
      end
    end
  end
end
