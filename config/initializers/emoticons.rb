# frozen_string_literal: true

path = Rails.root.join("config/emoticons.json")
JSON.parse(path.read).each do |emoji|
  Emoji.create(emoji.fetch("name")) do |char|
    char.image_filename = emoji.fetch("image_filename")
  end
end
