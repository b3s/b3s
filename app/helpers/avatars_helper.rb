# frozen_string_literal: true

require "digest/sha2"

module AvatarsHelper
  def avatar_image_tag(user)
    if user.avatar
      dynamic_image_tag(user.avatar, { crop: true }.merge(avatar_options(user)))
    else
      image_tag(identicon_data_uri(user), avatar_options(user))
    end
  end

  private

  def identicon_data_uri(user)
    "data:image/svg+xml;base64,#{Base64.strict_encode64(identicon_svg(user))}"
  end

  def avatar_options(user)
    {
      size: "96x96",
      alt: user.username,
      class: "avatar-image"
    }
  end

  def identicon_svg(user)
    bytes = Digest::SHA256.digest("identicon:#{user.id}").bytes
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-0.5 -0.5 6 6" ' \
      'shape-rendering="crispEdges">' \
      '<rect x="-0.5" y="-0.5" width="6" height="6" fill="#f0f0f0"/>' \
      "<path fill=\"#{identicon_color(bytes)}\" " \
      "d=\"#{identicon_path(bytes)}\"/></svg>"
  end

  def identicon_path(bytes)
    cells = (0...5).to_a.product((0...3).to_a)
    cells.select { |row, col| bytes[(row * 3) + col].even? }
         .flat_map { |row, col| [col, 4 - col].uniq.map { |x| [x, row] } }
         .map { |x, y| "M#{x} #{y}h1v1h-1z" }
         .join
  end

  def identicon_color(bytes)
    hue = ((bytes[15] << 8) | bytes[16]) * 360 / 65_536
    saturation = 45 + (bytes[17] % 20)
    lightness = 40 + (bytes[18] % 20)
    "hsl(#{hue},#{saturation}%,#{lightness}%)"
  end
end
