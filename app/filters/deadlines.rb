# frozen_string_literal: true

module Deadlines
  private

  def deadline_resolver(deadline, tag)
    dns = Resolv::DNS.new.tap { it.timeouts = 1 }
    lambda do |host|
      throw tag if monotonic_now >= deadline
      next [IPAddr.new(host)] if Resolv::AddressRegex.match?(host)

      dns.getaddresses(host).map { IPAddr.new(it.to_s) }
    end
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
