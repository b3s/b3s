# frozen_string_literal: true

module SystemHelpers
  def login_as(user = nil)
    user ||= create(:new_user)
    login_with(user.email, user.password)
  end

  def login_with(email, password)
    visit new_session_path
    fill_in "email", with: email
    fill_in "password", with: password
    click_on "Sign in"
  end

  def user_is_logged_in
    expect(page).to(have_text("Sign out"))
  end

  def user_is_logged_out
    expect(page).to(have_no_text("Sign out"))
  end
end
