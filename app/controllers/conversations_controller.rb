# frozen_string_literal: true

class ConversationsController < ApplicationController
  requires_authentication
  requires_user

  protect_from_forgery except: %i[mark_as_read]

  before_action :find_exchange, except: %i[index new create]
  before_action :find_recipient, only: [:create]

  def index
    @exchanges = current_user.conversations.page(params[:page]).for_view
    respond_with_exchanges(@exchanges)
  end

  def show
    @page = params[:page] || 1
    @posts = @exchange.posts.page(@page, context:).for_view

    mark_as_viewed!(@exchange, @posts.last, @posts.offset_value + @posts.count)

    respond_with_exchange(@exchange, @page)

    current_user.mark_conversation_viewed(@exchange)
  end

  def new
    @exchange = Conversation.new
    @recipient = User.find_by(username: params[:username]) if params[:username]
    @moderators = true if params[:moderators]
    render "exchanges/new"
  end

  def edit
    if @exchange.editable_by?(current_user)
      @exchange.body = @exchange.posts.first.body
      render "exchanges/edit"
    else
      render_error 403
    end
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

  def mute
    current_user.conversation_relationships
                .find_by(conversation: @exchange)
                .update(notifications: false)
    redirect_to conversation_url(@exchange, page: params[:page])
  end

  def unmute
    current_user.conversation_relationships
                .find_by(conversation: @exchange)
                .update(notifications: true)
    redirect_to conversation_url(@exchange, page: params[:page])
  end

  def update
    return render_error 403 unless @exchange.editable_by?(current_user)

    if @exchange.update(exchange_params.merge(updated_by: current_user))
      flash[:notice] = t("changes_saved")
      redirect_to @exchange
    else
      flash.now[:notice] = t("exchange.invalid")
      render "exchanges/edit"
    end
  end

  def mark_as_read
    mark_as_viewed!(@exchange, @exchange.posts.last, @exchange.posts_count)
    render layout: false, plain: "OK" if request.xhr?
  end

  private

  def context
    mobile_variant? ? 0 : 3
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

  def mark_as_viewed!(exchange, last_post, count)
    return unless current_user?

    current_user.mark_exchange_viewed(exchange, last_post, count)
  end
end
