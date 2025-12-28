# frozen_string_literal: true

class PostsController < ApplicationController
  requires_authentication
  requires_user

  def search
    @search_path = search_posts_path
    @posts = Post.search(search_query).page(params[:page])
  end
end
