# frozen_string_literal: true

module LayoutHelper
  def body_class
    classes = (content_for(:body_class) || "").split(/\s+/)
    classes << "with_sidebar" if content_for?(:sidebar)
    classes.uniq.join(" ")
  end

  def discussion_action?(action)
    params[:controller] == "discussions" && params[:action] == action
  end

  def frontend_configuration
    { emoticons: enabled_emoticons,
      amazonAssociatesId: B3S.config.amazon_associates_id,
      uploads: true,
      currentUserId: current_user&.id,
      currentUser: current_user.try(&:as_json),
      preferredFormat: current_user.try(&:preferred_format) }
  end

  def search_mode_options(exchange)
    options = [["Discussions", search_path],
               ["Posts", search_posts_path]]
    if exchange&.id
      options << ["This #{exchange.type.downcase}",
                  polymorphic_path([:search, exchange, :posts])]
    end
    options
  end

  def header_tab(name, url, options = {})
    section = options[:section] || name.downcase.to_sym

    classes = [section.to_s] + Array(options[:class])
    classes << "current" if respond_to?(:current_section) && section == current_section

    tag.li(link_to(name, url, id: options[:id] || "#{section}_link"),
           class: classes)
  end

  private

  def enabled_emoticons
    B3S.config.emoticons.split(/\s+/).filter_map do |name|
      emoji = Emoji.find_by_alias(name)
      { name:, image: emoji_path(emoji) } if emoji
    end
  end
end
