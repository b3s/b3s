# frozen_string_literal: true

module PostsHelper
  def emojify(content)
    return if content.blank?

    # Only escape if content isn't already safe HTML
    content_str = content.html_safe? ? content : h(content)

    safe_scan_and_replace(content_str, /:([\w+-]+):/) do |match|
      emoji = Emoji.find_by_alias(match[1])
      emoji ? emoji_tag(emoji, alt: match[1]) : match[0]
    end
  end

  def emoji_tag(emoji, alt:)
    tag(:img,
        alt:,
        class: "emoji",
        src: emoji_path(emoji),
        style: "vertical-align:middle",
        width: 16, height: 16)
  rescue ActionView::Template::Error
    # Return the unicode character for the emoji
    emoji.raw || ":#{alt}:"
  end

  def format_post(content, user)
    emojify(meify(content, user))
  end

  def meify(string, user)
    safe_scan_and_replace(string, %r{(^|<\w+\s?/?>|\s)/me}) do |match|
      safe_join([match[1], profile_link(user, nil, class: :poster)])
    end
  end

  def render_post(string)
    Renderer.render(string)
  end

  private

  def safe_scan_and_replace(content, pattern)
    parts = []
    last_end = 0

    content.scan(pattern) do
      match = Regexp.last_match
      parts << content[last_end...match.begin(0)] if match.begin(0) > last_end
      parts << yield(match)
      last_end = match.end(0)
    end

    parts << content[last_end..] if last_end < content.length
    safe_join(parts)
  end
end
