# frozen_string_literal: true

class ImageFetcher
  attr_accessor :body

  class << self
    def fetch(body)
      new(body).fetch
    end
  end

  def initialize(body)
    @body = body
  end

  def fetch
    fetch_tagged_images(
      fetch_markdown_images(
        fetch_autolinked_images(body)
      )
    )
  end

  private

  def fetch_autolinked_images(str)
    str.gsub(%r{(^|\s)((ftp|https?)://[^\s]+\.(jpg|jpeg|gif|png)\b/?)}i) do
      pre = Regexp.last_match(1)
      match = Regexp.last_match(2)

      uri = extract_uri(match)
      image = fetch_image(uri)

      pre + (image ? match.gsub(uri, embed_image(image)) : match)
    end
  end

  def fetch_markdown_images(str)
    str.gsub(
      %r{((!\[[^\]]*\])(\((ftp|https?)://[^\s]+\.(jpg|jpeg|gif|png)\b/?)\))}i
    ) do
      full = Regexp.last_match(1)
      match = Regexp.last_match(3)
      uri = extract_uri(match)
      post_image = fetch_image(uri)
      post_image ? embed_image(post_image) : full
    end
  end

  def fetch_tagged_images(str)
    Nokogiri::HTML::DocumentFragment.parse(str).css("img").each do |element|
      post_image = fetch_image(elem_src(element))
      next unless post_image

      [
        element.to_s,
        element.to_s.gsub(/>$/, "/>"), # Nokogiri botches self-closing tags
        element.to_s.gsub(/>$/, " />")
      ].each { |pattern| str = str.gsub(pattern, embed_image(post_image)) }
    end
    str
  end

  def extract_uri(str)
    URI.extract(str).try(:first)
  end

  def fetch_image(uri)
    return nil unless uri
    # Only fetch imgurl URLs for now
    return nil unless host_whitelist?(URI.parse(uri).hostname)

    find_image(uri) || create_image(uri)
  end

  def host_whitelist?(hostname)
    %w[i.imgur.com m.imgur.com].include?(hostname)
  end

  def find_image(uri)
    PostImage.find_by(original_url: uri)
  end

  def src?(elem)
    elem.attributes && elem.attributes["src"].present?
  end

  def elem_src(elem)
    elem.attributes["src"].to_s if src?(elem)
  end

  def create_tempfile(data)
    Tempfile.new("post-image-temp").tap do |f|
      f.binmode
      f.write data
      f.rewind
    end
  end

  def embed_image(post_image)
    "[image:#{post_image.id}:#{post_image.content_hash}]"
  end

  def uploaded_file(request)
    Rack::Test::UploadedFile.new(
      create_tempfile(request.body),
      request.headers["Content-Type"]
    )
  end

  def create_image(uri)
    request = Typhoeus.get(uri)
    return nil unless request.success?

    image = PostImage.create(
      data: uploaded_file(request),
      content_type: request.headers["Content-Type"],
      filename: filename(uri),
      original_url: uri
    )
    image if image.valid?
  end

  def filename(uri)
    URI.parse(uri).path.split("/").last
  end
end
