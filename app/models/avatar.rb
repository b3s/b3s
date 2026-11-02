# frozen_string_literal: true

class Avatar < ApplicationRecord
  include DynamicImage::Model
  include ImagePixelLimit

  has_one :user, dependent: :nullify
end
