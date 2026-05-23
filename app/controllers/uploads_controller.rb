# frozen_string_literal: true

class UploadsController < ApplicationController
  requires_authentication
  requires_user

  def create
    post_image = find_or_create_post_image(upload_params[:file])
    return upload_error("Invalid image") unless post_image.valid?

    respond_to do |format|
      format.json { render json: post_image_response(post_image) }
    end
  rescue Vips::Error, DynamicImage::Errors::InvalidHeader,
         DynamicImage::Errors::InvalidImage
    upload_error("Invalid image")
  end

  private

  def find_or_create_post_image(file)
    post_image = PostImage.new(file:)
    return post_image unless post_image.valid?

    PostImage.find_by(content_hash: post_image.content_hash) ||
      post_image.tap(&:save)
  end

  def post_image_response(post_image)
    {
      name: post_image.filename,
      type: post_image.content_type,
      embed: "[image:#{post_image.id}:#{post_image.content_hash}]"
    }
  end

  def upload_error(error)
    response = { error: }
    respond_to do |format|
      format.json { render json: response, status: :unprocessable_content }
    end
  end

  def upload_params
    params.expect(upload: %i[file])
  end
end
