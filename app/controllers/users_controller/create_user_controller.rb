# frozen_string_literal: true

class UsersController < ApplicationController
  module CreateUserController
    extend ActiveSupport::Concern

    included do
      before_action :find_invite,               only: %i[new create]
      before_action :check_for_expired_invite,  only: %i[new create]
      before_action :check_for_signups_allowed, only: %i[new create]
    end

    def new
      if @invite
        session[:invite_token] = @invite.token
        @user = @invite.user.invitees.new
        @user.email = @invite.email
      else
        @user = User.new
      end
    end

    def create
      @user = User.new(new_user_params)
      @user.invite = @invite # This can be nil

      if @user.save
        finalize_successful_signup
        redirect_to user_profile_url(id: @user.username)
      else
        flash.now[:notice] = t("signup.invalid")
        render action: :new
      end
    end

    private

    def new_user_params
      params.expect(user: [:username, *allowed_params])
    end

    def find_invite
      @invite = Invite.find_by(token: invite_token) if invite_token?
    end

    def invite_token
      params[:token] || session[:invite_token]
    end

    def invite_token?
      invite_token ? true : false
    end

    def finalize_successful_signup
      Mailer.new_user(@user, login_users_url).deliver_later if @user.email?
      session.delete(:invite_token)
      authenticate!(@user)
    end

    def check_for_expired_invite
      return unless @invite&.expired?

      session.delete(:invite_token)
      flash[:notice] = t("invite.expired")
      redirect_to login_users_url
    end

    def check_for_signups_allowed
      return unless !B3S.config.signups_allowed && User.any? && !@invite

      flash[:notice] = t("signup.not_allowed")
      redirect_to login_users_url
    end
  end
end
