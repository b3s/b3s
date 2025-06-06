# frozen_string_literal: true

module PostingController
  extend ActiveSupport::Concern

  private

  def build_preview_post(exchange, attrs)
    exchange.posts.new(attrs).tap do |post|
      post.fetch_images
      post.body_html # Render post to trigger any errors
    end
  end

  def create_post(create_params)
    @post = @exchange.posts.create(create_params)
    @exchange.reload

    exchange_url = polymorphic_url(@exchange,
                                   page: @exchange.last_page,
                                   anchor: "post-#{@post.id}")

    # if @exchange.is_a?(Conversation)
    #   ConversationNotifier.new(@post, exchange_url).deliver_later
    # end

    respond_with_created_post(@post, exchange_url)
  end

  def find_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.expect(post: %i[body format])
  end

  def render_post_error(msg)
    render plain: msg, status: :internal_server_error if request.xhr?
  end

  def respond_with_created_post(post, redirect_url)
    respond_to do |format|
      if post.valid?
        format.html { redirect_to redirect_url }
        format.json { render json: post, status: :created }
      else
        format.html { render :new }
        format.json { render json: post, status: :unprocessable_entity }
      end
    end
  end

  def respond_with_updated_post(post, redirect_url)
    respond_to do |format|
      if post.valid?
        format.html { redirect_to redirect_url }
        format.json { render json: post }
      else
        format.html { render :edit }
        format.json { render json: post, status: :unprocessable_entity }
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
