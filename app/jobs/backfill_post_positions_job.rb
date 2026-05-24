# frozen_string_literal: true

class BackfillPostPositionsJob < ApplicationJob
  queue_as :default

  def perform(exchange_id)
    Post.connection.exec_update(<<~SQL.squish, "BackfillPostPositionsJob", [exchange_id])
      UPDATE posts SET position = sub.rn
      FROM (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM posts
        WHERE exchange_id = $1 AND position IS NULL
      ) sub
      WHERE posts.id = sub.id
    SQL
  end
end
