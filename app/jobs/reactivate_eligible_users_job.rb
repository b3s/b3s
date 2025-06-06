# frozen_string_literal: true

class ReactivateEligibleUsersJob < ApplicationJob
  def perform
    User.temporarily_deactivated.find_each(&:reactivate_if_eligible!)
  end
end
