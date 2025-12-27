# frozen_string_literal: true

module LoginMacros
  def login_as(user)
    return unless user

    post(session_path,
         params: { email: user.email,
                   password: user.password })
  end
end
