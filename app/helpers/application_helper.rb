# frozen_string_literal: true

module ApplicationHelper
  include AvatarsHelper
  include CurrentUserHelper
  include EmojiHelper
  include ExchangesHelper
  include IconsHelper
  include LayoutHelper
  include PaginationHelper
  include PostsHelper
  include DynamicImage::Helper

  def page_title_tag
    tag.title(safe_join([content_for(:page_title),
                         B3S.config.forum_name].compact, " - "))
  end

  def pretty_link(url)
    url = "http://#{url}" unless %r{^(f|ht)tps?://}.match?(url)
    url = url.gsub(%r{/$}, "") if %r{^(f|ht)tps?://[\w\d\-.]*/$}.match?(url)
    link_to url.gsub(%r{^(f|ht)tps?://}, ""), url
  end

  def possessive(noun)
    noun.match?(/s$/) ? "#{noun}'" : "#{noun}'s"
  end

  # Generates a link to the users profile
  def profile_link(user, link_text = nil, options = {})
    if user
      link_text ||= user.username
      link_to(
        link_text,
        user_profile_path(user.username),
        { title: "#{possessive(user.username)} profile" }.merge(options)
      )
    else
      "Unknown"
    end
  end

  def user_link(link)
    return link.name_or_pretty_url unless link.url?

    link_to(link.name_or_pretty_url, link.url)
  end
end
