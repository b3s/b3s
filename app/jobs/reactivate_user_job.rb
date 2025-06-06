# frozen_string_literal: true

class ReactivateUserJob < ApplicationJob
  def perform(user_id)
    User.find_by(id: user_id)&.reactivate_if_eligible!
  end
end
