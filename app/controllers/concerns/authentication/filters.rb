# frozen_string_literal: true

module Authentication
  module Filters
    def requires_authentication(*)
      send(:before_action, *) do |controller|
        controller.send(:require_user_account) unless B3S.public_browsing?
      end
    end

    def requires_user(*)
      send(:before_action, *) do |controller|
        controller.send(:require_user_account)
      end
    end

    def requires_admin(*)
      send(:before_action, *) do |controller|
        controller.send(:verify_user, admin: true)
      end
    end

    def requires_moderator(*)
      send(:before_action, *) do |controller|
        controller.send(:verify_user, moderator: true)
      end
    end

    def requires_user_admin(*)
      send(:before_action, *) do |controller|
        controller.send(:verify_user, user_admin: true)
      end
    end
  end
end
