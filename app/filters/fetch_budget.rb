# frozen_string_literal: true

class FetchBudget
  MAX_FETCHES = 25
  RENDER_BUDGET = 6

  def spend?
    @deadline ||= monotonic_now + RENDER_BUDGET
    @fetches = (@fetches || 0) + 1
    @fetches <= MAX_FETCHES && monotonic_now < @deadline
  end

  private

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
