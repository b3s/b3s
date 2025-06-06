# frozen_string_literal: true

module Authentication
  module Controller
    extend ActiveSupport::Concern
    include ActionView::Helpers::DateHelper
    include CurrentUserHelper

    included do
      before_action :load_session_user,
                    :verify_active_account
      after_action :update_last_active,
                   :store_session_authentication
    end

    protected

    def authentication_failure_notice
      t("authentication.notice.#{current_user.status}", duration: ban_duration)
    end

    def authentication_log_line(user)
      if user.active?
        "Authenticated as user:#{user.id} (#{user.username})"
      else
        "Authentication failed for user:#{user.id} " \
          "(#{user.username}) - #{user.status}"
      end
    end

    def load_session_user
      return unless session[:user_id] &&
                    session[:persistence_token] &&
                    !current_user?

      user = User.find_by(id: session[:user_id])
      return unless user&.persistence_token == session[:persistence_token]

      authenticate!(user)
    end

    def ban_duration
      return nil unless current_user.temporary_banned?

      distance_of_time_in_words(Time.zone.now, current_user.banned_until)
    end

    def verify_active_account
      return unless current_user?

      current_user.reactivate_if_eligible!
      logger.info(authentication_log_line(current_user))
      return if current_user.active?

      flash[:notice] = authentication_failure_notice
      deauthenticate!
    end

    def authenticate!(user)
      raise "Already authenticated" if authenticated?
      return unless user

      @authenticated_session = {
        user_id: user.id,
        persistence_token: user.persistence_token
      }.freeze
    end

    def deauthenticate!
      @authenticated_session = {}.freeze
      @current_user = nil
    end

    def update_last_active
      current_user.mark_active! if current_user?
    end

    def store_session_authentication
      unless authenticated_session[:user_id] == current_user&.id
        raise "Authentication mismatch between authenticated_session and " \
              "current_user. Has current_user been mutated?"
      end

      session[:user_id] = authenticated_session[:user_id]
      session[:persistence_token] = authenticated_session[:persistence_token]
    end
  end
end
