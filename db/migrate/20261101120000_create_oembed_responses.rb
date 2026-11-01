# frozen_string_literal: true

class CreateOembedResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :oembed_responses do |t|
      t.text :url, null: false, index: { unique: true }
      t.text :html, null: false
      t.datetime :fetched_at, null: false
      t.timestamps
    end
  end
end
