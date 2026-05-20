# frozen_string_literal: true

class PostsController < ApplicationController
  requires_authentication
  requires_user except: %i[show]

  def show
    post = Post.find(params.expect(:id))
    raise ActiveRecord::RecordNotFound unless post.exchange.viewable_by?(current_user)

    redirect_to polymorphic_url(post.exchange,
                                page: post.page,
                                anchor: "post-#{post.id}")
  end

  def search
    @search_path = search_posts_path
    @posts = Post.search(search_query).page(params[:page])
  end
end
