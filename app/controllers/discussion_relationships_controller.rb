# frozen_string_literal: true

class DiscussionRelationshipsController < ApplicationController
  requires_authentication
  requires_user

  before_action :find_discussion

  def follow
    DiscussionRelationship.define(current_user, @discussion, following: true)
    redirect_to discussion_url(@discussion, page: params[:page])
  end

  def unfollow
    DiscussionRelationship.define(current_user, @discussion, following: false)
    redirect_to discussions_url
  end

  def favorite
    DiscussionRelationship.define(current_user, @discussion, favorite: true)
    redirect_to discussion_url(@discussion, page: params[:page])
  end

  def unfavorite
    DiscussionRelationship.define(current_user, @discussion, favorite: false)
    redirect_to discussions_url
  end

  def hide
    DiscussionRelationship.define(current_user, @discussion, hidden: true)
    redirect_to discussions_url
  end

  def unhide
    DiscussionRelationship.define(current_user, @discussion, hidden: false)
    redirect_to discussion_url(@discussion, page: params[:page])
  end

  private

  def find_discussion
    @discussion = Discussion.find(params[:discussion_id])
    render_error 403 unless @discussion.viewable_by?(current_user)
  end
end
