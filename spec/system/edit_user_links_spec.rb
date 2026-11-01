# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editing user links", :js do
  let!(:user) { create(:user) }

  before do
    login_as(user)
    find_link("Sign out", visible: :all)
  end

  def add_link(label, url)
    click_on "Add link"
    fill_in "label", with: label
    fill_in "url", with: url
    click_on "Add"
  end

  def visit_editor
    visit edit_user_profile_path(user.username, page: "links")
  end

  it "makes unsaved link hrefs absolute" do
    visit_editor
    add_link("Website", "example.com/foo")
    expect(page).to have_link("example.com/foo", href: "https://example.com/foo")
  end

  context "when links are saved" do
    before do
      visit_editor
      add_link("Website", "example.com/foo")
      add_link("Portfolio", "example.photography")
      click_on "Save"
      find("body", text: "Your changes were saved")
      visit user_profile_path(user.username)
    end

    it "renders the links with absolute hrefs" do
      expect(page).to have_link("example.com/foo", href: "https://example.com/foo")
        .and have_link("example.photography", href: "https://example.photography")
    end
  end

  it "shows an uppercase scheme without the scheme" do
    create(:user_link, user:, name: nil, url: "HTTP://example.com/foo")
    visit_editor
    expect(page).to have_link("example.com/foo", href: "HTTP://example.com/foo")
  end

  it "renders a legacy non-http URL as text" do
    build(:user_link, user:, name: nil, url: "javascript:alert(1)").save(validate: false)
    visit_editor
    expect(find(".user-link", text: "javascript:alert(1)")).to have_no_css("a")
  end

  it "rejects a URL with another scheme" do
    visit_editor
    click_on "Add link"
    fill_in "label", with: "Email"
    fill_in "url", with: "mailto:someone@example.com"
    expect(page).to have_button("Add", disabled: true)
  end

  context "when the server rejects a link" do
    before do
      visit_editor
      add_link("Website", "example.comm")
      click_on "Save"
      find("body", text: "Couldn't save your changes")
    end

    it "keeps the link in the editor" do
      expect(page).to have_link("example.comm", href: "https://example.comm")
    end

    it "shows the error next to the link" do
      expect(find(".user-link", text: "example.comm"))
        .to have_css(".link-errors", text: "URL doesn't have a valid domain")
    end
  end
end
