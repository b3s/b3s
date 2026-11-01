# frozen_string_literal: true

module Rack
  class Attack
    ### Throttle Spammy Clients ###

    # Throttle all requests by IP (60rpm)
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
    throttle("req/ip", limit: 300, period: 5.minutes, &:ip)
  end
end
