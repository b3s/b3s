# frozen_string_literal: true

require "digest/sha1"

class ExchangePostsController < ApplicationController
  requires_authentication except: %i[count]
  requires_user except: %i[count since search]

  before_action :find_exchange
  before_action :find_post, only: %i[edit update]
  before_action :verify_editable, only: %i[edit update]
  before_action :verify_postable, only: %i[create preview]
  before_action :verify_viewable

  after_action :mark_conversation_viewed, only: %i[since]
  after_action :mark_exchange_viewed, only: %i[since]

  rescue_from URI::InvalidURIError, with: :handle_invalid_uri

  def count
    @count = @exchange.posts_count
    respond_to do |format|
      format.json { render json: { posts_count: @count }.to_json }
    end
  end

  def since
    @posts = @exchange.posts.limit(200).offset(params[:index]).for_view
    render layout: false if request.xhr?
  end

  def search
    @search_path = polymorphic_path([:search, @exchange, :posts])
    @posts = @exchange.posts.search_in_exchange(search_query).page(params[:page])
    render "exchanges/search_posts"
  end

  def edit
    render layout: false if request.xhr?
  end

  def create
    create_post(post_params.merge(user: current_user))
  end

  def update
    @post.update(post_params.merge(edited_at: Time.now.utc))

    post_url = polymorphic_url(@exchange, page: @post.page, anchor: "post-#{@post.id}")

    respond_with_post(@post, post_url)
  end

  def preview
    @post = @exchange.posts.new(post_params.merge(user: current_user))
                     .tap(&:fetch_images).tap(&:body_html)

    render layout: false if request.xhr?
  end

  private

  def find_exchange
    @exchange = Exchange.find(params.permit(:discussion_id, :conversation_id, :exchange_id).values.first)
  end

  def mark_exchange_viewed
    return unless current_user? && @posts.any?

    current_user.mark_exchange_viewed(@exchange, @posts.last, params[:index].to_i + @posts.length)
  end

  def mark_conversation_viewed
    return unless current_user? && @exchange.is_a?(Conversation)

    current_user.mark_conversation_viewed(@exchange)
  end

  def verify_viewable
    return if @exchange&.viewable_by?(current_user)

    flash[:notice] = t("exchange.not_viewable")
    redirect_to root_url
  end

  def create_post(create_params)
    @post = @exchange.posts.create(create_params)
    @exchange.reload

    exchange_url = polymorphic_url(@exchange, page: @exchange.last_page, anchor: "post-#{@post.id}")

    respond_with_post(@post, exchange_url, created: true)
  end

  def find_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.expect(post: %i[body format])
  end

  def handle_invalid_uri(exception)
    render plain: exception.message, status: :internal_server_error if request.xhr?
  end

  def respond_with_post(post, redirect_url, created: false)
    respond_to do |format|
      if post.valid?
        format.html { redirect_to redirect_url }
        format.json { render json: post, status: (created ? :created : :ok) }
      else
        format.html { render created ? :new : :edit }
        format.json { render json: post, status: :unprocessable_content }
      end
    end
  end

  def verify_editable
    return if @post.editable_by?(current_user)

    flash[:notice] = t("post.not_editable")
    redirect_to polymorphic_url(@exchange, page: @exchange.last_page)
  end

  def verify_postable
    return if @exchange.postable_by?(current_user)

    flash[:notice] = t("exchange.closed")
    redirect_to polymorphic_url(@exchange, page: @exchange.last_page)
  end
end
