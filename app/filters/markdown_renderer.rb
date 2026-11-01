# frozen_string_literal: true

class MarkdownRenderer < Redcarpet::Render::HTML
  include ActionView::Helpers::TagHelper

  def preprocess(document)
    document = normalize_newlines(document)
    document = escape_leading_gts_without_space(document)
    document = separate_adjacent_blockquotes(document)
    youtube_embed(document)
  end

  def block_html(raw_html)
    render_spoiler(raw_html)
  end

  def postprocess(document)
    document.gsub("<div class=\"strip-me\"></div>\n\n", "")
  end

  private

  def render_spoiler(str)
    if str.strip =~ %r{\A<div class="spoiler">(.*)</div>\n?\z}m
      "<div class=\"spoiler\">" \
        "#{MarkdownFilter.new(Regexp.last_match(1)).to_html}</div>\n"
    else
      str
    end
  end

  def normalize_newlines(document)
    document.gsub(/\r\n?/, "\n")
  end

  def separate_adjacent_blockquotes(document)
    document.gsub(/\n+\n(?=\s*>)/, "\n\n<div class=\"strip-me\"></div>\n\n")
  end

  def escape_leading_gts_without_space(document)
    document.gsub(/^(\s*)(>+)([^\s>])/) do
      Regexp.last_match(1) +
        ("&gt;" * Regexp.last_match(2).length) +
        Regexp.last_match(3)
    end
  end

  def youtube_id(url)
    if url =~ %r{youtu\.be/([^?]*)}
      Regexp.last_match(1)
    else
      url.match(%r{^.*((v/)|(embed/)|(watch\?))\??v?=?([^&?]*).*})&.[](5)
    end
  end

  def youtube_embed(document)
    document.gsub(/!y\[(.*)\]\((.*)\)/) do |code|
      title = Regexp.last_match(1)
      id = youtube_id(Regexp.last_match(2))
      next code unless id

      tag.div(class: "youtube-embed", data: { youtube_id: id, youtube_title: title })
    end
  end
end
