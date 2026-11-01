# frozen_string_literal: true

module Rack
  class Attack
    ### Throttle Spammy Clients ###

    # Throttle all requests by IP (60rpm)
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
    throttle("req/ip", limit: 300, period: 5.minutes, &:ip)

    ### Prevent Brute-Force Login Attacks ###

    # Throttle POST requests to /session by IP address
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
    throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
      req.ip if req.path == "/session" && req.post?
    end

    # Throttle POST requests to /session by email param
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{normalized_email}"
    throttle("logins/email", limit: 5, period: 20.seconds) do |req|
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence if req.path == "/session" && req.post?
    end

    ### Prevent Password Reset Abuse ###

    # Throttle POST requests to /password_reset by IP address
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:password_resets/ip:#{req.ip}"
    throttle("password_resets/ip", limit: 5, period: 15.minutes) do |req|
      req.ip if req.path == "/password_reset" && req.post?
    end

    # Throttle POST requests to /password_reset by email param
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:password_resets/email:#{normalized_email}"
    throttle("password_resets/email", limit: 5, period: 15.minutes) do |req|
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence if req.path == "/password_reset" && req.post?
    end

    ### Throttled Responses ###

    # Respond to throttled password resets as if the reset was sent
    default_throttled_responder = throttled_responder
    self.throttled_responder = lambda do |req|
      return default_throttled_responder.call(req) unless req.env["rack.attack.matched"].start_with?("password_resets/")

      request = ActionDispatch::Request.new(req.env)
      request.flash[:notice] = I18n.t("password_reset.sent")
      request.commit_flash
      headers = Rails.application.config.action_dispatch.default_headers.merge(
        "referrer-policy" => "no-referrer",
        "location" => "#{request.base_url}/session/new",
        "content-type" => "text/html; charset=utf-8",
        "content-length" => "0"
      )
      [302, headers, []]
    end
  end
end
