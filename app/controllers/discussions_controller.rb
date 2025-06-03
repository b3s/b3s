# frozen_string_literal: true

class DiscussionsController < ApplicationController
  include DiscussionRelationshipsController
  include ExchangesController

  requires_authentication
  requires_user except: %i[index search search_posts show]

  before_action :find_exchange, except: %i[
    index new create popular search favorites following hidden
  ]

  def index
    scope = current_user&.unhidden_discussions || Discussion
    @exchanges = scope.viewable_by(current_user).page(params[:page]).for_view
    respond_with_exchanges(@exchanges)
  end

  def popular
    @days = (params[:days] || 7).to_i
    @days = 180 if @days > 180
    @exchanges = Discussion.popular_in_the_last(@days.days)
                           .viewable_by(current_user).page(params[:page])
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

  def new
    @exchange = Discussion.new
    render template: "exchanges/new"
  end

  def create
    @exchange = Discussion.create(exchange_params.merge(poster: current_user))
    if @exchange.valid?
      redirect_to @exchange
    else
      flash.now[:notice] = "Could not save your discussion! " \
                           "Please make sure all required fields are filled in."
      render template: "exchanges/new"
    end
  end

  private

  def current_section
    case params[:action]
    when "favorites"
      :favorites
    when "following"
      :following
    else
      super
    end
  end

  def exchange_params
    params.expect(
      discussion: %i[title body format nsfw closed] +
                  (current_user.moderator? ? %i[sticky] : [])
    )
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
    current_user.send(method)
                .viewable_by(current_user).page(params[:page]).for_view
  end
end
