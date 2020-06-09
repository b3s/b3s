# frozen_string_literal: true

module LayoutHelper
  def add_body_class(*class_names)
    @body_classes ||= []
    @body_classes += Array(class_names)
  end

  def body_classes
    @body_classes ||= []
    @body_classes << "with_sidebar" if content_for?(:sidebar) && !@body_classes.include?("with_sidebar")
    @body_classes.uniq.join(" ")
  end

  def discussion_action?(action)
    params[:controller] == "discussions" && params[:action] == action
  end

  def frontend_configuration
    {
      authToken: form_authenticity_token,
      debug: Rails.env.development?,
      emoticons: enabled_emoticons,
      facebookAppId: Sugar.config.facebook_app_id,
      amazonAssociatesId: Sugar.config.amazon_associates_id,
      uploads: Sugar.aws_s3?,
      currentUser: current_user.try(&:as_json),
      preferredFormat: current_user.try(&:preferred_format)
    }
  end

  def search_mode_options
    options = [["Discussions", search_path], ["Posts", search_posts_path]]
    if @exchange&.id
      options << [
        "This #{@exchange.type.downcase}",
        polymorphic_path([:search_posts, @exchange])
      ]
    end
    options
  end

  def header_tab(name, url, options = {})
    section = options[:section] || name.downcase.to_sym

    classes = [section.to_s] + Array(options[:class])
    classes << "current" if @section == section

    content_tag(
      :li,
      link_to(name, url, id: (options[:id] || "#{section}_link")),
      class: classes
    )
  end

  private

  def enabled_emoticons
    Sugar.config.emoticons.split(/\s+/).map do |name|
      emoji = Emoji.find_by_alias(name)
      { name: name, image: emoji_path(emoji) } if emoji
    end.compact
  end
end
