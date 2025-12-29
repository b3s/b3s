# frozen_string_literal: true

module ExchangesHelper
  # Returns an array of class names for an exchange
  def exchange_classes(collection, exchange)
    [
      exchange.labels.map(&:downcase),
      %w[odd even][collection.to_a.index(exchange) % 2],
      (new_posts?(exchange) ? "new_posts" : nil),
      "by_user#{exchange.poster_id}",
      "discussion",
      "discussion#{exchange.id}"
    ].flatten.compact
  end

  def new_posts_count(exchange)
    viewed_tracker.new_posts(exchange)
  end

  delegate :new_posts?, to: :viewed_tracker

  def last_viewed_page_path(exchange)
    last_page    = viewed_tracker.last_page(exchange)
    last_post_id = viewed_tracker.last_post_id(exchange)
    options = {}
    options[:page]   = last_page if last_page > 1
    options[:anchor] = "post-#{last_post_id}" if last_post_id

    polymorphic_path(exchange, options)
  end

  def muted_user_ids(exchange)
    return [] unless current_user?

    current_user.muted_user_ids(exchange:)
  end

  def post_page(post, posts = nil)
    # Speed optimization
    if (controller.is_a?(DiscussionsController) || controller.is_a?(ConversationsController)) &&
       params[:action] == "show" && posts
      posts.current_page
    else
      post.page
    end
  end
end
