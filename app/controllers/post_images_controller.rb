# frozen_string_literal: true

class PostImagesController < ApplicationController
  include DynamicImage::Controller

  before_action { request.session_options[:skip] = true }

  private

  def model
    PostImage
  end
end
