# frozen_string_literal: true

class AddPartialGinIndexOnPostsTsv < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :posts, :tsv,
              using: :gin,
              where: "conversation = false AND deleted = false",
              name: "index_posts_on_tsv_searchable",
              algorithm: :concurrently
  end
end
