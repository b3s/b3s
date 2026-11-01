# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :set_referrer_policy
  before_action :store_token, only: %i[show]
  before_action :find_by_token, only: %i[show update]

  def show; end

  def new; end

  def create
    @user = User.where(email: params[:email]).first if params[:email]
    deliver_password_reset(@user) if @user
    flash[:notice] = t("password_reset.sent")
    redirect_to new_session_url
  end

  def update
    if user_params[:password].present? && @user.update(user_params)
      session.delete(:password_reset_token)
      authenticate!(@user)
      flash[:notice] = t("password_reset.changed")
      redirect_to root_url
    else
      render :show
    end
  end

  private

  def deliver_password_reset(user)
    Mailer.password_reset(
      user.email,
      password_reset_url(token: user.generate_token_for(:password_reset))
    ).deliver_later
  end

  def fail_reset(message)
    flash[:notice] = message
    redirect_to new_session_url
  end

  def find_by_token
    @user = User.find_by_token_for(:password_reset,
                                   session[:password_reset_token].to_s)
    fail_reset(t("password_reset.invalid")) unless @user
  end

  def set_referrer_policy
    response.set_header("Referrer-Policy", "no-referrer")
  end

  def store_token
    token = params[:token]&.to_s
    return unless token

    if User.find_by_token_for(:password_reset, token)
      session[:password_reset_token] = token
      redirect_to password_reset_url
    else
      session.delete(:password_reset_token)
      fail_reset(t("password_reset.invalid"))
    end
  end

  def user_params
    params.expect(user: %i[password password_confirmation])
  end
end
