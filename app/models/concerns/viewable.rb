# frozen_string_literal: true

module Viewable
  extend ActiveSupport::Concern

  module ClassMethods
    def viewable_by(_)
      all
    end
  end

  # Returns true if the user can view this record
  def viewable_by?(user)
    B3S.public_browsing? || user ? true : false
  end
end
