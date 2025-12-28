# frozen_string_literal: true

module Users
  class PostsController < ApplicationController
    requires_authentication

    before_action :load_user

    def index
      @posts = @user.discussion_posts
                    .viewable_by(current_user)
                    .page(params[:page])
                    .for_view_with_exchange
                    .reverse_order
    end

    private

    def load_user
      @user = User.find_by(username: params[:user_profile_id]) ||
              User.find(params[:user_profile_id])
    end
  end
end
