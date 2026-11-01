# frozen_string_literal: true

module PostsHelper
  def emojify(content)
    return if content.blank?

    transform_text_nodes(content) { |fragment| emojify_fragment(fragment) }
  end

  def emoji_tag(emoji, alt:)
    tag(:img,
        alt:,
        class: "emoji",
        src: emoji_path(emoji),
        style: "vertical-align:middle",
        width: 16, height: 16)
  rescue ActionView::Template::Error, Propshaft::MissingAssetError
    # Return the unicode character for the emoji
    emoji.raw || ":#{alt}:"
  end

  def format_post(content, user)
    return if content.blank?

    transform_text_nodes(content) do |fragment|
      meify_fragment(fragment, user)
      emojify_fragment(fragment)
    end
  end

  def meify(string, user)
    return if string.blank?

    transform_text_nodes(string) { |fragment| meify_fragment(fragment, user) }
  end

  def render_post(string)
    Renderer.render(string)
  end

  def post_timestamp_link(post)
    if post.persisted?
      link_to(time_tag(post.created_at, class: "relative date"),
              post_path(post),
              title: "Permalink to this post",
              class: "permalink")
    else
      tag.time("Preview", class: "relative date")
    end
  end

  private

  def transform_text_nodes(content)
    fragment = Nokogiri::HTML5.fragment(content.html_safe? ? content.to_str : "")
    fragment.add_child(fragment.document.create_text_node(content)) unless content.html_safe?
    yield fragment
    fragment.to_html.html_safe
  end

  def text_nodes(fragment)
    skipped = %w[a code pre script style textarea]
    nodes = []
    fragment.traverse do |node|
      nodes << node if node.text? && node.ancestors.none? { |a| skipped.include?(a.name) }
    end
    nodes
  end

  def emojify_fragment(fragment)
    text_nodes(fragment).each do |node|
      replace_in_text_node(node, /:([\w+-]+):/) do |match|
        emoji = Emoji.find_by_alias(match[1])
        emoji ? emoji_tag(emoji, alt: match[1]) : match[0]
      end
    end
  end

  def meify_fragment(fragment, user)
    text_nodes(fragment).each do |node|
      pattern = line_start?(node) ? %r{(\A|\s)/me} : %r{(\s)/me}
      replace_in_text_node(node, pattern) do |match|
        [match[1], profile_link(user, nil, class: :poster)]
      end
    end
  end

  def line_start?(node)
    previous = node.previous_sibling
    previous.nil? || (previous.element? && previous.name == "br")
  end

  def replace_in_text_node(node, pattern, &)
    text = node.content
    return unless text.match?(pattern)

    split_text(text, pattern, &).reject(&:empty?).each do |part|
      node.add_previous_sibling(build_nodes(node.document, part))
    end
    node.remove
  end

  def split_text(text, pattern)
    parts = []
    last_end = 0
    text.scan(pattern) do
      match = Regexp.last_match
      parts << text[last_end...match.begin(0)]
      parts.concat(Array(yield(match)))
      last_end = match.end(0)
    end
    parts << text[last_end..]
  end

  def build_nodes(document, part)
    return document.create_text_node(part) unless part.html_safe?

    Nokogiri::HTML5::DocumentFragment.new(document, part.to_str)
  end
end
