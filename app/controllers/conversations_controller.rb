# frozen_string_literal: true

class ConversationsController < ApplicationController
  include ExchangesController

  requires_authentication
  requires_user

  before_action :find_exchange, except: %i[index new create]
  before_action :find_recipient, only: [:create]
  before_action :find_remove_user, only: [:remove_participant]

  def index
    @exchanges = current_user.conversations.page(params[:page]).for_view
    respond_with_exchanges(@exchanges)
  end

  def show
    super
    current_user.mark_conversation_viewed(@exchange)
  end

  def new
    @exchange = Conversation.new
    @recipient = User.find_by(username: params[:username]) if params[:username]
    @moderators = true if params[:moderators]
    render "exchanges/new"
  end

  def create
    @moderators = true if params[:moderators]
    @exchange = create_exchange(recipient: @recipient, moderators: @moderators)
    if @exchange.valid?
      redirect_to @exchange
    else
      flash.now[:notice] = t("conversation.invalid")
      render "exchanges/new"
    end
  end

  def invite_participant
    if params[:username]
      add_participants(@exchange, params[:username].split(/\s*,\s*/))
    end
    redirect_to @exchange
  end

  def remove_participant
    @exchange.remove_participant(@user)

    if @user == current_user
      flash[:notice] = t("conversation.you_have_been_removed")
      redirect_to conversations_url
    else
      flash[:notice] = t("conversation.user_removed", username: @user.username)
      redirect_to @exchange
    end
  end

  def mute
    current_user.conversation_relationships
                .find_by(conversation: @exchange).update(notifications: false)
    redirect_to conversation_url(@exchange, page: params[:page])
  end

  def unmute
    current_user.conversation_relationships
                .find_by(conversation: @exchange).update(notifications: true)
    redirect_to conversation_url(@exchange, page: params[:page])
  end

  private

  def add_participants(exchange, usernames)
    usernames.each do |username|
      user = User.find_by(username:)
      exchange.add_participant(user) if user
    end
  end

  def create_exchange(recipient:, moderators:)
    exchange = Conversation.create(exchange_params.merge(poster: current_user))
    if exchange.valid?
      exchange.add_participant(recipient) if recipient
      User.admins.each { |u| exchange.add_participant(u) } if moderators
    end
    exchange
  end

  def exchange_params
    params.expect(conversation: %i[recipient_id title body format])
  end

  def find_exchange
    @exchange = Conversation.find(params[:id])
    render_error 403 unless @exchange.viewable_by?(current_user)
  end

  def find_recipient
    @recipient = User.find_by(id: params[:recipient_id])
  end

  def find_remove_user
    @user = User.find_by(username: params[:username])
    return if @exchange.removeable_by?(@user, current_user)

    flash[:error] = t("conversation.not_removeable")
    redirect_to @exchange
  end
end
