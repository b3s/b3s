# frozen_string_literal: true

class RaiseStatisticsTargetOnPostsTsv < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE posts ALTER COLUMN tsv SET STATISTICS 5000"
    execute "ANALYZE posts"
  end

  def down
    execute "ALTER TABLE posts ALTER COLUMN tsv SET STATISTICS DEFAULT"
  end
end
