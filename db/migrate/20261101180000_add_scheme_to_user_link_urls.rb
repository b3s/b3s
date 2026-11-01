# frozen_string_literal: true

class AddSchemeToUserLinkUrls < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE user_links
      SET url = 'https://' || btrim(url)
      WHERE btrim(url) ~* '^[a-z0-9-]+(\\.[a-z0-9-]+)+(/|$)'
        AND btrim(url) !~* '^https?://'
    SQL
  end

  def down; end
end
