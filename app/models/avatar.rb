# frozen_string_literal: true

class Avatar < ApplicationRecord
  include DynamicImage::Model

  has_one :user, dependent: :nullify
end
