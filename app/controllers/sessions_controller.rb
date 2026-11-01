# frozen_string_literal: true

class SessionsController < ApplicationController
  rate_limit to: 5, within: 20.seconds, only: :create, with: :too_many_requests
  rate_limit to: 5, within: 20.seconds, only: :create, with: :too_many_requests,
             by: :normalized_email_param, name: "email", if: :normalized_email_param
  before_action :detect_admin_signup, only: %i[new create]
  requires_no_user only: %i[new create]
  requires_user only: %i[destroy_everywhere]

  def new
    # Renders login form
  end

  def create
    user = find_and_authenticate_user
    if user
      renew_session
      authenticate!(user)
      redirect_to discussions_url
    else
      flash.now[:notice] = t("authentication.invalid")
      render :new
    end
  end

  def destroy
    renew_session
    deauthenticate!
    flash[:notice] = t("authentication.logged_out")
    redirect_to B3S.public_browsing? ? discussions_url : new_session_url
  end

  def destroy_everywhere
    current_user.log_out_everywhere!
    renew_session
    deauthenticate!
    flash[:notice] = t("authentication.logged_out_everywhere")
    redirect_to new_session_url
  end

  private

  def find_and_authenticate_user
    User.find_and_authenticate_with_password(
      params[:email].to_s,
      params[:password]
    )
  end

  def too_many_requests
    render plain: "Retry later\n", status: :too_many_requests
  end

  def detect_admin_signup
    return if User.any?

    redirect_to new_registration_path
  end
end
