# frozen_string_literal: true

class LinkFilter < Filter
  HTTPS_WHITELIST = %w[
    youtube.com
    *.youtube.com
    vimeo.com
    soundcloud.com
    i.imgur.com
    *.cloudfront.net
    *.s3.amazonaws.com
  ].freeze

  def process(post)
    @post = post
    relativize_local_links!
    rewrite_for_https_support!
    parser.to_html
  end

  private

  def extract_href(elem)
    elem.try(:attributes).try(:[], "href").try(:value)
  end

  def head_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 2
    http.read_timeout = 5

    http.start do |h|
      h.head(uri.request_uri).code
    end
  end

  def local_domain?(host)
    local_domains.detect { |d| host == d }
  end

  def local_domains
    B3S.config.domain_names.try(:strip).try(:split, /\s*,\s*/) || []
  end

  def parser
    @parser ||= Nokogiri::HTML::DocumentFragment.parse(@post)
  end

  def matches_https_whitelist?(url)
    host = URI.parse(url).host
    return false unless host

    HTTPS_WHITELIST.detect { |domain| File.fnmatch(domain, host) }
  end

  def https_url_exists?(url)
    uri = URI.parse(url.gsub(%r{^(https?:)//}, "https://"))
    begin
      head_request(uri) =~ /^(2|3)\d\d$/
    rescue SocketError, Net::OpenTimeout,
           OpenSSL::SSL::SSLError, Errno::ECONNREFUSED
      false
    rescue StandardError => e
      logger.error "Unexpected connection error #{e.inspect}"
      false
    end
  end

  def relativize_local_links!
    parser.search("a").each do |link|
      href = extract_href(link)
      next unless href&.match?(%r{^https?://})

      host = URI.parse(href).host
      next unless local_domain?(host)

      link.set_attribute(
        "href",
        href.gsub(Regexp.new("(https?:)?//#{Regexp.escape(host)}"), "")
      )
    end
  end

  def rewrite_for_https?(src)
    matches_https_whitelist?(src) ||
      (src.start_with?("http://") && https_url_exists?(src))
  end

  def rewrite_for_https_support!
    parser.css("iframe,img").each do |iframe|
      src = iframe.try(:attributes).try(:[], "src").try(:value)
      next unless src && rewrite_for_https?(src)

      iframe.set_attribute("src", src.gsub(%r{\Ahttps?://}, "//"))
    end
  end
end
