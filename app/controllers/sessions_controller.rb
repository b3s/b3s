# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :detect_admin_signup, only: %i[new create]
  requires_no_user only: %i[new create]

  def new
    # Renders login form
  end

  def create
    user = find_and_authenticate_user
    if user
      authenticate!(user)
      redirect_to discussions_url
    else
      flash.now[:notice] = t("authentication.invalid")
      render :new
    end
  end

  def destroy
    deauthenticate!
    flash[:notice] = t("authentication.logged_out")
    redirect_to B3S.public_browsing? ? discussions_url : new_session_url
  end

  private

  def find_and_authenticate_user
    User.find_and_authenticate_with_password(
      params[:email],
      params[:password]
    )
  end

  def detect_admin_signup
    return if User.any?

    redirect_to new_registration_path
  end
end
