# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: proc { B3S.config.mail_sender || "no-reply@example.com" }
end
