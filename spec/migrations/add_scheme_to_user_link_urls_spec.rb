# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261101180000_add_scheme_to_user_link_urls.rb")

describe AddSchemeToUserLinkUrls do
  let(:expected) do
    { "example.com/foo" => "https://example.com/foo",
      " example.com " => "https://example.com",
      "http://example.com" => "http://example.com",
      "https://example.com" => "https://example.com",
      "HTTP://example.com" => "HTTP://example.com",
      "" => "",
      nil => nil }
  end

  let!(:links) { expected.keys.index_with { |url| create_link_with_raw_url(url) } }

  def create_link_with_raw_url(url)
    link = create(:user_link)
    ActiveRecord::Base.connection.exec_update(
      "UPDATE user_links SET url = $1 WHERE id = $2", "SQL", [url, link.id]
    )
    link
  end

  def urls
    links.transform_values { |link| link.reload.url }
  end

  def migrate
    ActiveRecord::Migration.suppress_messages { described_class.new.up }
  end

  it "adds a scheme to URLs without one" do
    migrate
    expect(urls).to eq(expected)
  end

  it "is idempotent" do
    migrate
    expect { migrate }.not_to(change { urls })
  end
end
