# frozen_string_literal: true

class RegistrationsController < ApplicationController
  requires_no_user only: %i[new create]
  before_action :find_invite, only: %i[new create]
  before_action :check_for_expired_invite, only: %i[new create]
  before_action :check_for_signups_allowed, only: %i[new create]

  def new
    if @invite
      @user = @invite.user.invitees.new
      @user.email = @invite.email
    else
      @user = User.new
    end
  end

  def create
    @user = User.new(user_params)
    @user.invite = @invite

    if @user.save
      finalize_successful_signup
      redirect_to user_profile_url(@user.username)
    else
      flash.now[:notice] = t("signup.invalid")
      render :new
    end
  end

  private

  def require_no_user_account
    flash[:notice] = t("invite.signed_in") if current_user? && session[:invite_token]
    super
  end

  def user_params
    params.expect(
      user: %i[username email password password_confirmation
               realname location]
    )
  end

  def find_invite
    token = session[:invite_token]
    @invite = Invite.find_by(token: token.to_s) if token
  end

  def finalize_successful_signup
    Mailer.new_user(@user).deliver_later if @user.email?
    session.delete(:invite_token)
    authenticate!(@user)
  end

  def check_for_expired_invite
    return unless @invite&.expired?

    session.delete(:invite_token)
    flash[:notice] = t("invite.expired")
    redirect_to new_session_url
  end

  def check_for_signups_allowed
    return unless !B3S.config.signups_allowed && User.any? && !@invite

    flash[:notice] = t("signup.not_allowed")
    redirect_to new_session_url
  end
end
