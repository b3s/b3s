# frozen_string_literal: true

class RaiseStatisticsTargetOnPostsTsv < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE posts ALTER COLUMN tsv SET STATISTICS 5000"
    # ANALYZE is left to autovacuum or a manual run; doing it inline
    # exceeds the web container's 30s deploy health-check timeout.
  end

  def down
    execute "ALTER TABLE posts ALTER COLUMN tsv SET STATISTICS DEFAULT"
  end
end
