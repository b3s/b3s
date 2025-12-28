# frozen_string_literal: true

module Users
  class InvitesController < ApplicationController
    requires_authentication
    requires_user_admin only: %i[create destroy]

    before_action :load_user

    def create
      @user.grant_invite!
      flash[:notice] = t("user.granted_invite", username: @user.username)
      redirect_to user_profile_url(@user.username)
    end

    def destroy
      @user.revoke_invite!(:all)
      flash[:notice] = t("user.revoked_invites",
                         username: @user.username)
      redirect_to user_profile_url(@user.username)
    end

    private

    def load_user
      @user = User.find_by(username: params[:user_id]) ||
              User.find(params[:user_id])
    end
  end
end
