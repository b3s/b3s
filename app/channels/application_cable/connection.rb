# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session = cookies.encrypted[Rails.application.config.session_options[:key]] || {}
      user = User.find_by(id: session["user_id"])

      if user&.active? && user.persistence_token == session["persistence_token"]
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
