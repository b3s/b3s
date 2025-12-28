# frozen_string_literal: true

module Users
  class DiscussionsController < ApplicationController
    requires_authentication

    before_action :load_user

    def index
      @discussions = @user.discussions.viewable_by(current_user)
                          .page(params[:page]).for_view
      respond_with_exchanges(@discussions)
    end

    def participated
      @discussions = @user.participated_discussions
                          .viewable_by(current_user)
                          .page(params[:page]).for_view
      respond_with_exchanges(@discussions)
    end

    private

    def load_user
      @user = User.find_by(username: params[:user_profile_id]) ||
              User.find(params[:user_profile_id])
    end
  end
end
