# frozen_string_literal: true

class AddUniqueIndexOnPostsExchangePosition < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :posts, %i[exchange_id position],
              unique: true,
              algorithm: :concurrently
  end
end
