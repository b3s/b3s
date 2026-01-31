# frozen_string_literal: true

class AvatarsController < ApplicationController
  include DynamicImage::Controller

  before_action { request.session_options[:skip] = true }

  private

  def model
    Avatar
  end
end
