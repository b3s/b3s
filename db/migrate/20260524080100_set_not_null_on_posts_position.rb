# frozen_string_literal: true

class SetNotNullOnPostsPosition < ActiveRecord::Migration[8.1]
  def up
    add_check_constraint :posts, "position IS NOT NULL",
                         name: "posts_position_check", validate: false
    validate_check_constraint :posts, name: "posts_position_check"
    change_column_null :posts, :position, false
    remove_check_constraint :posts, name: "posts_position_check"
  end

  def down
    change_column_null :posts, :position, true
  end
end
