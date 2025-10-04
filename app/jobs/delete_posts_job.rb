# frozen_string_literal: true

class DeletePostsJob < ApplicationJob
  def perform(user_id)
    user = User.find_by(id: user_id)

    user.posts.in_batches do |posts|
      posts.update(deleted: true, skip_html: true)
    end

    user.update(public_posts_count: user.discussion_posts.count)
  end
end
