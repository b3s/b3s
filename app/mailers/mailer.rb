# frozen_string_literal: true

class Mailer < ApplicationMailer
  def invite(invite)
    @invite = invite
    @url    = accept_invites_url(token: invite.token)
    mail(
      to: @invite.email,
      subject: "#{@invite.user.realname_or_username} has invited you to " \
               "#{B3S.config.forum_name}!"
    )
  end

  def new_user(user)
    @user = user
    @url  = new_session_url
    mail(
      to: @user.email,
      subject: "Welcome to #{B3S.config.forum_name}!"
    )
  end

  def password_reset(user)
    @url = password_reset_url(token: user.generate_token_for(:password_reset))
    mail(
      to: user.email,
      subject: "Password reset for #{B3S.config.forum_name}"
    )
  end
end
