# frozen_string_literal: true

module UsersHelper
  def status_options
    User.statuses.keys.map do |status|
      [t("user.status.#{status}"), status]
    end
  end

  def current_users_tab?(options)
    controller = options[:controller] || "users/lists"
    return false unless controller == params[:controller]

    (options[:action] && options[:action] == params[:action]) ||
      options[:controller]
  end

  def users_tab(name, path, options = {})
    classes = ["tab", options[:class]].compact
    classes << "active" if current_users_tab?(options)
    tag.li(link_to(name, path), class: classes.join(" "))
  end
end
