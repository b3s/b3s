# frozen_string_literal: true

class DeletePostsJob < ApplicationJob
  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    user.posts.in_batches do |posts|
      # rubocop:disable-next Rails/SkipsModelValidations
      posts.update_all(deleted: true, updated_at: Time.now.utc)
    end

    user.update(public_posts_count: user.discussion_posts.count)
  end
end
