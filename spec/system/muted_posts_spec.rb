# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Muted posts", :js do
  let!(:user) { create(:user) }
  let(:muted_user) { create(:user, username: "<i>muted") }
  let(:discussion) { create(:discussion, poster: user) }

  before do
    configure(default_mobile_theme: "b3s")
    user.mute!(muted_user)
    create(:post, exchange: discussion, user: muted_user, body: "Hidden")
  end

  def sign_in(button, sign_out_link)
    visit new_session_path
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_on button
    find_link(sign_out_link, visible: :all)
  end

  it "shows the muted username as text" do
    sign_in("Sign in", "Sign out")
    visit discussion_path(discussion)
    expect(find(".muted-notice strong").text).to eq("<i>muted")
  end

  context "with the mobile layout" do
    before do
      driven_by :selenium, using: :headless_chrome,
                           options: { name: :headless_chrome_mobile } do |options|
        options.add_argument(
          "--user-agent=Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) " \
          "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 " \
          "Mobile/15E148 Safari/604.1"
        )
      end
    end

    it "shows the muted username as text" do
      sign_in("Login", "Log out")
      visit discussion_path(discussion)
      expect(find(".muted-notice strong").text).to eq("<i>muted")
    end
  end
end
