# frozen_string_literal: true

class InvitesController < ApplicationController
  requires_authentication except: [:accept]
  requires_user except: [:accept]
  requires_user_admin only: [:all]

  before_action :find_invite, only: %i[destroy]
  before_action :find_invite_by_token, only: %i[accept]
  before_action :verify_available_invites, only: %i[new create]

  def index
    @invites = current_user.invites.active
  end

  def all
    @invites = Invite.active
  end

  def accept
    session[:invite_token] = session_invite_token(@invite)
    if expire_invite(@invite)
      flash[:notice] ||= t("invite.expired")
    elsif @invite
      redirect_to new_user_by_token_url(token: @invite.token)
      return
    else
      flash[:notice] ||= t("invite.invalid")
    end
    redirect_to login_users_url
  end

  def new
    @invite = current_user.invites.new
  end

  def create
    @invite = create_invite(invite_params)

    if @invite.invalid?
      render action: :new
      return
    elsif deliver_invite!(@invite)
      flash[:notice] = t("invite.sent", email: @invite.email)
    else
      flash[:notice] = t("invite.failed", email: @invite.email)
    end
    redirect_to invites_url
  end

  def destroy
    return unless verify_user(user: @invite.user, user_admin: true)

    @invite.destroy
    flash[:notice] = t("invite.cancelled")
    redirect_to invites_url
  end

  private

  def create_invite(attrs)
    current_user.invites.create(attrs)
  end

  def deliver_invite!(invite)
    Mailer.invite(invite, accept_invite_url(id: invite.token)).deliver_later
  rescue Net::SMTPFatalError, Net::SMTPSyntaxError
    @invite.destroy
    false
  end

  def expire_invite(invite)
    return false unless invite&.expired?

    @invite.destroy
  end

  def invite_params
    params.require(:invite).permit(:email, :message)
  end

  def find_invite
    @invite = Invite.find(params[:id])
  end

  def find_invite_by_token
    @invite = Invite.find_by(token: params[:id])
  end

  def session_invite_token(invite)
    return unless invite
    return if invite.expired?

    invite.token
  end

  def verify_available_invites
    return if current_user? && current_user.available_invites?

    respond_to do |format|
      format.html do
        flash[:notice] = t("invite.no_invites")
        redirect_to online_users_url
      end
      format.json do
        render(text: t("invite.no_invites"), status: :method_not_allowed)
      end
    end
  end
end
