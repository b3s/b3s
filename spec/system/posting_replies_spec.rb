# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Posting replies", :js do
  let(:user) { create(:user) }
  let(:discussion) { create(:discussion) }

  around do |example|
    original_host = Capybara.app_host
    original_include_port = Capybara.always_include_port
    Capybara.app_host = "http://reply-host.localhost"
    Capybara.always_include_port = true
    example.run
  ensure
    Capybara.app_host = original_host
    Capybara.always_include_port = original_include_port
  end

  before do
    create(:post, exchange: discussion, body: "First post")
    login_as(user)
    find_link("Sign out")
    visit discussion_path(discussion)
  end

  context "when the forum's hostname contains a hyphen" do
    it "shows the new post without reloading" do
      fill_in "compose-body", with: "A fresh reply"
      click_on "Post"
      expect(page).to have_css(".post .body .content", text: "A fresh reply")
    end
  end
end
