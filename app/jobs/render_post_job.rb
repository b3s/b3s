# frozen_string_literal: true

class RenderPostJob < ApplicationJob
  retry_on EmbedFilter::FetchFailed, wait: :polynomially_longer, attempts: 15 do |job, _error|
    job.render_post(strict: false)
  end

  def perform(_post_id)
    render_post(strict: true)
  end

  def render_post(strict:)
    post = Post.find_by(id: arguments.first)
    return unless post

    source = [post.body, post.format]
    html = Renderer.render(post.body, format: post.format, fetch_budget: FetchBudget.unlimited, strict:)
    post.with_lock do
      next unless [post.body, post.format] == source

      post.skip_preprocess = true
      post.update!(body_html: html)
    end
  end
end
