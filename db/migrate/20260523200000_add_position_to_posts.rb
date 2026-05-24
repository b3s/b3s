# frozen_string_literal: true

class AddPositionToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :position, :integer
  end
end
