# frozen_string_literal: true

module ImagePixelLimit
  extend ActiveSupport::Concern

  included do
    validate :validate_pixel_count
  end

  private

  def validate_pixel_count
    return unless real_width && real_height
    return unless real_width * real_height * (frame_count || 1) > 250_000_000

    errors.add(:data, :too_many_pixels, count: 250)
  end
end
