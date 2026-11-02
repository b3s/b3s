# frozen_string_literal: true

class PostImage < ApplicationRecord
  include DynamicImage::Model
  include ImagePixelLimit
end
