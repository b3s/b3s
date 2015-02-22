# encoding: utf-8

class InvitesController < ApplicationController
  requires_authentication except: [:accept]
  requires_user except: [:accept]
  requires_user_admin only: [:all]

  respond_to :html, :mobile, :xml, :json

  before_action :find_invite, only: [:show, :edit, :update, :destroy]
  before_action :verify_available_invites, only: [:new, :create]

  def index
    respond_with(@invites = current_user.invites.active)
  end

  def all
    respond_with(@invites = Invite.active)
  end

  def accept
    @invite = Invite.find_by_token(params[:id])
    session[:invite_token] = nil
    if @invite && @invite.expired?
      @invite.destroy
      flash[:notice] ||= "Your invite has expired!"
    elsif @invite
      session[:invite_token] = @invite.token
      redirect_to new_user_by_token_url(token: @invite.token)
      return
    else
      flash[:notice] ||= "That's not a valid invite!"
    end
    redirect_to login_users_url
  end

  def new
    respond_with(@invite = current_user.invites.new)
  end

  def create
    @invite = current_user.invites.create(invite_params)
    if @invite.valid?
      begin
        Mailer.invite(@invite, accept_invite_url(id: @invite.token)).deliver_now
        flash[:notice] = "Your invite has been sent to #{@invite.email}"
      rescue Net::SMTPFatalError, Net::SMTPSyntaxError
        flash[:notice] = "There was a problem sending your invite to " +
          "#{@invite.email}, it has been cancelled."
        @invite.destroy
      end
      redirect_to invites_url
    else
      render action: :new
    end
  end

  def destroy
    if verify_user(user: @invite.user, user_admin: true)
      @invite.destroy
      flash[:notice] = "Your invite has been cancelled."
      redirect_to invites_url
    end
  end

  private

  def invite_params
    params.require(:invite).permit(:email, :message)
  end

  # Finds the requested invite
  def find_invite
    @invite = Invite.find(params[:id])
  end

  def verify_available_invites
    unless current_user? && current_user.available_invites?
      respond_to do |format|
        format.any(:html, :mobile) do
          flash[:notice] = "You don't have any invites!"
          redirect_to online_users_url
        end
        format.any(:xml, :json) do
          render(
            text: "You don't have any invites!",
            status: :method_not_allowed
          )
        end
      end
    end
  end
end
