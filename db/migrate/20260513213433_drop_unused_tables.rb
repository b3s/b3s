# frozen_string_literal: true

class DropUnusedTables < ActiveRecord::Migration[8.1]
  def change
    drop_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false

      t.index %i[blob_id variation_digest],
              name: "index_active_storage_variant_records_uniqueness",
              unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    drop_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false

      t.datetime :created_at, null: false

      t.index %i[record_type record_id name blob_id],
              name: "index_active_storage_attachments_uniqueness",
              unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    drop_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false

      t.index [:key], unique: true
    end

    drop_table :delayed_jobs do |t|
      t.integer :priority, default: 0
      t.integer :attempts, default: 0
      t.text :handler
      t.string :last_error
      t.datetime :run_at
      t.datetime :locked_at
      t.datetime :failed_at
      t.string :locked_by
      t.timestamps null: false
    end
  end
end
