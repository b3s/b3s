# frozen_string_literal: true

class AddSearchIndices < ActiveRecord::Migration[7.0]
  def up
    add_column :exchanges, :tsv, :tsvector
    add_index :exchanges, :tsv, using: "gin"
    add_column :posts, :tsv, :tsvector
    add_index :posts, :tsv, using: "gin"

    execute <<~SQL.squish
      CREATE EXTENSION IF NOT EXISTS unaccent;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      DROP TEXT SEARCH CONFIGURATION IF EXISTS english_unaccent;
      CREATE TEXT SEARCH CONFIGURATION english_unaccent (COPY = pg_catalog.english);
    SQL

    execute <<~SQL.squish
      ALTER TEXT SEARCH CONFIGURATION english_unaccent
        ALTER MAPPING FOR hword, hword_part, word
        WITH unaccent, simple;
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER tsvectorupdate_exchanges BEFORE INSERT OR UPDATE
      ON exchanges FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(tsv, 'public.english_unaccent', title);
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER tsvectorupdate_posts BEFORE INSERT OR UPDATE
      ON posts FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(tsv, 'public.english_unaccent', body);
    SQL

    execute("UPDATE exchanges SET title = title")
    execute("UPDATE posts SET body = body")
  end

  def down
    execute <<~SQL.squish
      DROP TRIGGER tsvectorupdate_posts ON posts;
      DROP TRIGGER tsvectorupdate_exchanges ON exchanges;
      DROP TEXT SEARCH CONFIGURATION english_unaccent;
    SQL

    remove_index :posts, :tsv
    remove_column :posts, :tsv
    remove_index :exchanges, :tsv
    remove_column :exchanges, :tsv
  end
end
