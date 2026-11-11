# frozen_string_literal: true

require "rails_helper"

describe LegacyEmbeds do
  describe ".oembed_url" do
    {
      "http://www.youtube.com/v/dQw4w9WgXcQ&hl=en&fs=1" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "//www.youtube.com/v/dQw4w9WgXcQ" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "https://youtube.com/embed/dQw4w9WgXcQ" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "http://www.youtube-nocookie.com/v/dQw4w9WgXcQ" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "http://vimeo.com/moogaloop.swf?clip_id=123&server=vimeo.com" => "https://vimeo.com/123",
      "http://www.vimeo.com/moogaloop.swf?server=vimeo.com&clip_id=123" => "https://vimeo.com/123",
      "http://player.vimeo.com/video/123?title=0" => "https://vimeo.com/123",
      "http://www.dailymotion.com/swf/x1abcd&related=0" => "https://www.dailymotion.com/video/x1abcd",
      "http://www.dailymotion.com/swf/video/x1abcd" => "https://www.dailymotion.com/video/x1abcd",
      "http://player.soundcloud.com/player.swf?url=http%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F123&show_comments=true" =>
        "https://api.soundcloud.com/tracks/123",
      "https://player.soundcloud.com/player.swf?url=http%3A%2F%2Fsoundcloud.com%2Fsome-artist%2Fsome-track" =>
        "https://soundcloud.com/some-artist/some-track",
      "http://a1.soundcloud.com/player.swf?url=http%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F123" =>
        "https://api.soundcloud.com/tracks/123"
    }.each do |flash_url, oembed_url|
      context "when the URL is #{flash_url}" do
        subject { described_class.oembed_url(flash_url) }

        it { is_expected.to eq(oembed_url) }
      end
    end

    [
      "http://www.youtube.com/p/ABCDEF123456",
      "http://www.youtube.example.com/v/dQw4w9WgXcQ",
      "http://www.youtube.com/v/dQw4w9WgXcQextra",
      "http://www.flickr.com/apps/video/stewart.swf?photo_id=123",
      "http://player.soundcloud.com/player.swf?url=http%3A%2F%2Fexample.com%2Ftracks%2F123",
      "http://player.soundcloud.com/player.swf?url=%",
      "http://c.brightcove.com/services/viewer/federated_f9?playerID=123"
    ].each do |flash_url|
      context "when the URL is #{flash_url}" do
        subject { described_class.oembed_url(flash_url) }

        it { is_expected.to be_nil }
      end
    end
  end
end
