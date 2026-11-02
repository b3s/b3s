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
    exchange = Exchange.find(params.expect(:DiscussionID))
    raise ActiveRecord::RecordNotFound unless exchange.viewable_by?(current_user)

    headers["Status"] = "301 Moved Permanently"
    redirect_to polymorphic_url(exchange, page: params[:page])
  end

  # /vanilla/account.php?u=4
  def user
    headers["Status"] = "301 Moved Permanently"
    redirect_to user_profile_url(params[:u])
  end
end
