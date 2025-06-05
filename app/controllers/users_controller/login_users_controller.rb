# frozen_string_literal: true

class UsersController < ApplicationController
  module LoginUsersController
    extend ActiveSupport::Concern

    included do
      before_action :detect_admin_signup,        only: [:login]
      before_action :check_if_already_logged_in, only: %i[login authenticate]
    end

    def login; end

    def authenticate
      user = User.find_and_authenticate_with_password(params[:email],
                                                      params[:password])
      authenticate!(user)
      if current_user?
        redirect_to discussions_url
      else
        flash[:notice] ||= t("authentication.invalid")
        redirect_to login_users_url
      end
    end

    def logout
      deauthenticate!
      flash[:notice] = t("authentication.logged_out")
      redirect_to B3S.public_browsing? ? discussions_url : login_users_url
    end

    private

    def detect_admin_signup
      return if User.any?

      redirect_to new_user_path
    end

    def check_if_already_logged_in
      return unless current_user?

      redirect_to discussions_url
    end
  end
end
