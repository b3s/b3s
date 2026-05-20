# frozen_string_literal: true

class Mailer < ApplicationMailer
  def invite(invite, login_url)
    @invite    = invite
    @login_url = login_url
    mail(
      to: @invite.email,
      subject: "#{@invite.user.realname_or_username} has invited you to " \
               "#{B3S.config.forum_name}!"
    )
  end

  def new_user(user, login_url)
    @user      = user
    @login_url = login_url
    mail(
      to: @user.email,
      subject: "Welcome to #{B3S.config.forum_name}!"
    )
  end

  def password_reset(email, url)
    @url = url
    mail(
      to: email,
      subject: "Password reset for #{B3S.config.forum_name}"
    )
  end
end
