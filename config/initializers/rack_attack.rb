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
  end
end
