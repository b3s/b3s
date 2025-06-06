# frozen_string_literal: true

require "mail"

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      email = Mail::Address.new(value)
      valid = email.domain && email.address == value
      valid &&= email.domain.include?(".")
    rescue StandardError
      valid = false
    end
    return if valid

    record.errors.add(attribute, options[:message] || "is invalid")
  end
end
