# frozen_string_literal: true

require "open-uri"

class UsersController < ApplicationController
  requires_authentication except: %i[login authenticate logout new create]
  requires_user only: %i[edit update]
  requires_user_admin only: %i[grant_invite revoke_invites]

  include CreateUserController
  include LoginUsersController
  include UsersListController

  before_action :load_user,
                only: %i[show edit update participated discussions posts
                         grant_invite revoke_invites mute unmute]

  before_action :detect_edit_page, only: %i[edit update]
  before_action :verify_editable,  only: %i[edit update]

  def show
    respond_to do |format|
      format.html { @posts = user_posts(@user).limit(15) }
      format.json do
        render json: UserResource.new(@user)
      end
    end
  end

  def discussions
    @discussions = @user.discussions.viewable_by(current_user)
                        .page(params[:page]).for_view
    respond_with_exchanges(@discussions)
  end

  def participated
    @discussions = @user.participated_discussions.viewable_by(current_user)
                        .page(params[:page]).for_view
    respond_with_exchanges(@discussions)
  end

  def posts
    @posts = user_posts(@user)
  end

  def edit; end

  def update
    updated = update_user
    respond_with_user(@user) do
      if updated
        flash[:notice] = t("flash.changes_saved")
        redirect_to edit_user_page_url(id: @user.username, page: @page)
      else
        flash.now[:notice] = t("flash.invalid_record")
        render :edit
      end
    end
  end

  def mute
    current_user.mute!(@user)
    flash[:notice] = t("user.muted", username: @user.username)
    redirect_to user_profile_url(id: @user.username)
  end

  def unmute
    current_user.unmute!(@user)
    flash[:notice] = t("user.unmuted", username: @user.username)
    redirect_to user_profile_url(id: @user.username)
  end

  def grant_invite
    @user.grant_invite!
    flash[:notice] = t("user.granted_invite", username: @user.username)
    redirect_to user_profile_url(id: @user.username)
  end

  def revoke_invites
    @user.revoke_invite!(:all)
    flash[:notice] = t("user.revoked_invites", username: @user.username)
    redirect_to user_profile_url(id: @user.username)
  end

  private

  def load_user
    @user = User.find_by(username: params[:id]) || User.find(params[:id])
  end

  def detect_edit_page
    pages = %w[admin info location links settings hiatus]
    @page = pages.include?(params[:page]) ? params[:page] : "info"
  end

  def verify_editable
    verify_user(user: @user,
                user_admin: true,
                redirect: user_profile_url(@user.username))
  end

  def allowed_admin_params
    current_user? && current_user.admin? ? [:admin] : []
  end

  def allowed_params
    [:birthday, :description, :email, :pronouns, :latitude,
     :location, :longitude, :mobile_stylesheet_url, :mobile_theme,
     :notify_on_message, :realname, :stylesheet_url, :theme, :time_zone,
     :password, :password_confirmation, :hiatus_until, :preferred_format,
     { avatar_attributes: [:file],
       user_links_attributes: [%i[id position label name url _destroy]] }] +
      allowed_user_admin_params + allowed_admin_params
  end

  def allowed_user_admin_params
    return [] unless current_user&.user_admin?

    %i[username user_admin moderator available_invites status banned_until]
  end

  def respond_with_user(user, &)
    respond_to do |format|
      format.html(&)
      format.json { render json: UserResource.new(user) }
    end
  end

  def update_user
    return nil unless @user.update(user_params)

    current_user.reload if @user == current_user
    @user
  end

  def user_params
    params.expect(user: allowed_params)
  end

  def user_posts(user)
    user.discussion_posts.viewable_by(current_user)
        .page(params[:page]).for_view_with_exchange.reverse_order
  end
end
