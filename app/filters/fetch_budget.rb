# frozen_string_literal: true

class FetchBudget
  MAX_FETCHES = 25
  RENDER_BUDGET = 6

  def self.unlimited
    new(max_fetches: Float::INFINITY, seconds: Float::INFINITY)
  end

  def initialize(max_fetches: MAX_FETCHES, seconds: RENDER_BUDGET)
    @max_fetches = max_fetches
    @seconds = seconds
  end

  def spend?
    @deadline ||= monotonic_now + @seconds
    @fetches = (@fetches || 0) + 1
    @fetches <= @max_fetches && monotonic_now < @deadline
  end

  private

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
