# frozen_string_literal: true

# Controller for redirecting old URLs
class VanillaController < ApplicationController
  # /vanilla/?page=2
  def discussions
    headers["Status"] = "301 Moved Permanently"
    redirect_to paged_discussions_path(page: params[:page] || 1)
  end

  # /vanilla/comments.php?DiscussionID=13892&page=6
  def discussion
    headers["Status"] = "301 Moved Permanently"
    redirect_to polymorphic_url(
      Exchange.find(params[:DiscussionID]),
      page: params[:page]
    )
  end

  # /vanilla/account.php?u=4
  def user
    headers["Status"] = "301 Moved Permanently"
    redirect_to user_profile_url(params[:u])
  end
end
