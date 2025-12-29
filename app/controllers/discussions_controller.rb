# frozen_string_literal: true

class DiscussionsController < ApplicationController
  requires_authentication
  requires_user except: %i[index search show]

  protect_from_forgery except: %i[mark_as_read]

  before_action :find_exchange, only: %i[show edit update mark_as_read]

  def index
    scope = current_user&.unhidden_discussions || Discussion
    @exchanges = scope.viewable_by(current_user).page(params[:page]).for_view
    respond_with_exchanges(@exchanges)
  end

  def popular
    @days = (params[:days] || 7).to_i.clamp(1, 180)
    @exchanges = Discussion.popular_in_the_last(@days.days).viewable_by(current_user).page(params[:page])
    respond_with_exchanges(@exchanges)
  end

  def search
    @exchanges = Discussion.search(search_query).page(params[:page])
    @search_path = search_path
    respond_with_exchanges(@exchanges)
  end

  def favorites
    @exchanges = user_discussions(:favorite_discussions)
    respond_with_exchanges(@exchanges)
  end

  def following
    @exchanges = user_discussions(:followed_discussions)
    respond_with_exchanges(@exchanges)
  end

  def hidden
    @exchanges = user_discussions(:hidden_discussions)
    respond_with_exchanges(@exchanges)
  end

  def show
    @page = params[:page] || 1
    @posts = @exchange.posts.page(@page, context:).for_view

    mark_as_viewed!(@exchange, @posts.last, @posts.offset_value + @posts.count)

    respond_with_exchange(@exchange, @page)
  end

  def new
    @exchange = Discussion.new
    render "exchanges/new"
  end

  def edit
    return render_error 403 unless @exchange.editable_by?(current_user)

    @exchange.body = @exchange.posts.first.body
    render "exchanges/edit"
  end

  def create
    @exchange = Discussion.create(exchange_params.merge(poster: current_user))
    if @exchange.valid?
      redirect_to @exchange
    else
      flash.now[:notice] = t("exchange.invalid")
      render "exchanges/new"
    end
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

  def current_section
    params[:action].in?(%w[favorites following]) ? params[:action].to_sym : super
  end

  def exchange_params
    params.expect(discussion: %i[title body format nsfw closed] + (current_user.moderator? ? %i[sticky] : []))
  end

  def find_exchange
    @exchange = Exchange.find(params[:id])

    if !@exchange.is_a?(Discussion)
      redirect_to @exchange
    elsif !@exchange.viewable_by?(current_user)
      render_error 403
    end
  end

  def user_discussions(method)
    current_user.send(method).viewable_by(current_user).page(params[:page]).for_view
  end

  def mark_as_viewed!(exchange, last_post, count)
    current_user&.mark_exchange_viewed(exchange, last_post, count)
  end
end
