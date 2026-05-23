# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session = cookies.encrypted[Rails.application.config.session_options[:key]]
      reject_unauthorized_connection unless session.is_a?(Hash)

      user = User.find_by(id: session["user_id"])
      reject_unauthorized_connection unless
        user&.persistence_token == session["persistence_token"] && user.active?

      user
    end
  end
end
