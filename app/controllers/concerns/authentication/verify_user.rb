# frozen_string_literal: true

module Authentication
  module VerifyUser
    protected

    def default_verify_user_options(options = {})
      options[:redirect] ||= "/"
      options[:notice] ||= "You don't have permission to do that!"
      options[:api_notice] ||= options[:notice]
      options
    end

    def handle_unverified_user(options)
      respond_to do |format|
        format.html do
          flash[:notice] = options[:notice]
          redirect_to options[:redirect]
        end
        format.json { render json: options[:api_notice], status: :unauthorized }
      end
    end

    def require_user_account
      verify_user(
        user: :any,
        redirect: login_users_url,
        notice: "You must be logged in to do that",
        api_notice: "Authorization required"
      )
    end

    # Verifies the current_user. The user is considered verified if one or more
    # criteria are met. If not, a redirect is performed.
    #
    # Criteria:
    #
    #  :user       - Checks that current_user matches the given user or :any
    #  :admin      - Checks that current_user is an admin
    #  :moderator  - Checks that current_user is a moderator
    #  :user_admin - Checks that current_user is a user admin
    #
    # Other options:
    #
    #  :notice   - Notice to display if verification fails
    #  :redirect - URL to redirect to if verification fails
    #
    # Examples:
    #
    #  # Require any user
    #  verify_user(
    #    user: :any,
    #    redirect: login_users_url,
    #    notice: 'You must be logged in!'
    #  )
    #
    #  # Only accessible by a moderator
    #  verify_user(moderator: true, notice: 'You must be a moderator!')
    #
    #  # Only accessible by a user admin or the user who owns the invite
    #  verify_user(user: @invite.user, user_admin: true)
    #
    def verify_user(options = {})
      options = default_verify_user_options(options)

      if current_user?
        verified = verify_current_user?(options)
        verified ||= verify_current_user_flags?(options)
      else
        verified = false
      end

      handle_unverified_user(options) unless verified
      verified
    end

    def verify_current_user?(options = {})
      if options[:user]
        options[:user] == :any || options[:user] == current_user
      else
        false
      end
    end

    def verify_current_user_flags?(options = {})
      %i[admin moderator user_admin].each do |flag|
        return true if options[flag] && current_user.send(:"#{flag}?")
      end
      false
    end
  end
end
