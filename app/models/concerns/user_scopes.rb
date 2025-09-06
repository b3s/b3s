# frozen_string_literal: true

module UserScopes
  extend ActiveSupport::Concern

  module ClassMethods
    def active_and_memorialized
      where(status: %i[active memorialized])
    end

    def admins
      active_and_memorialized.where(
        "admin = ? OR user_admin = ? OR moderator = ?",
        true,
        true,
        true
      )
    end

    def temporarily_deactivated
      where(status: %i[hiatus time_out])
    end

    def deactivated
      where.not(status: %i[active memorialized])
    end

    def by_username
      order(:username)
    end

    def online
      active_and_memorialized.where("last_active > ?", 15.minutes.ago)
    end

    def recently_joined
      active_and_memorialized.order(created_at: :desc)
    end

    def top_posters
      active_and_memorialized.where("public_posts_count > 0")
                             .order(public_posts_count: :desc)
    end
  end
end
