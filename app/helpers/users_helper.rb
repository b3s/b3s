# frozen_string_literal: true

module UsersHelper
  def status_options
    User.statuses.keys.map do |status|
      [t("user.status.#{status}"), status]
    end
  end

  def user_status_label(user)
    case user.status
    when "memorialized" then tag.span("Memorialized", class: "memorialized")
    when "banned" then tag.span("Banned", class: "banned")
    when "inactive" then tag.span("Inactive", class: "banned")
    when "time_out" then temporary_ban_label("On time out", user.banned_until)
    when "hiatus" then temporary_ban_label("On hiatus", user.banned_until)
    else admin_status_label(user)
    end
  end

  def temporary_ban_label(text, banned_until)
    safe_join([tag.span(text, class: "banned"),
               " for #{distance_of_time_in_words(Time.current, banned_until)}"])
  end

  def admin_status_label(user)
    return unless user.user_admin? || user.moderator?

    tag.span(user.admin_labels.to_sentence, class: "admin")
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
