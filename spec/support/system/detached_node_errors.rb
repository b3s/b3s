# frozen_string_literal: true

module DetachedNodeErrors
  def execute(...)
    super
  rescue Selenium::WebDriver::Error::UnknownError => e
    raise unless e.message.include?("does not belong to the document")

    raise Selenium::WebDriver::Error::StaleElementReferenceError, e.message
  end
end

Selenium::WebDriver::Remote::Bridge.prepend(DetachedNodeErrors)
