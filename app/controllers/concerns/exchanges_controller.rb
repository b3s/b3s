# frozen_string_literal: true

module ExchangesController
  extend ActiveSupport::Concern

  included do
    protect_from_forgery except: [:mark_as_read]
  end

  def search_posts
    @search_path = polymorphic_path([:search_posts, @exchange])
    @posts = @exchange.posts
                      .search_in_exchange(search_query)
                      .page(params[:page])
    render "exchanges/search_posts"
  end

  def show
    @page = params[:page] || 1
    @posts = @exchange.posts.page(@page, context:).for_view

    mark_as_viewed!(@exchange, @posts.last,
                    @posts.offset_value + @posts.count)

    respond_with_exchange(@exchange, @page)
  end

  def edit
    if @exchange.editable_by?(current_user)
      @exchange.body = @exchange.posts.first.body
      render "exchanges/edit"
    else
      render_error 403
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
    mark_as_viewed!(
      @exchange,
      @exchange.posts.last,
      @exchange.posts_count
    )
    render layout: false, plain: "OK" if request.xhr?
  end

  protected

  def context
    mobile_variant? ? 0 : 3
  end

  def mark_as_viewed!(exchange, last_post, count)
    return unless current_user?

    current_user.mark_exchange_viewed(exchange, last_post, count)
  end

  def respond_with_exchange(exchange, page)
    respond_to do |format|
      format.html
      format.json do
        redirect_to(polymorphic_path([exchange, :posts], page:, format: :json))
      end
    end
  end
end
