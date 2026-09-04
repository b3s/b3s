# frozen_string_literal: true

class AddFrameCountAndAlphaToImageTables < ActiveRecord::Migration[8.1]
  TABLES = %i[avatars post_images].freeze

  def change
    TABLES.each do |table|
      change_table table, bulk: true do |t|
        t.column :frame_count, :integer
        t.column :alpha, :boolean
        t.index :content_hash
      end
    end
  end
end
