# frozen_string_literal: true

class DiscussionRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :discussion

  FLAG_COUNTERS = {
    participated: :participated_count,
    following: :following_count,
    favorite: :favorites_count,
    hidden: :hidden_count
  }.freeze

  before_validation :ensure_flags_are_mutually_exclusive

  after_create  :increment_user_caches
  after_update  :sync_user_caches_on_change
  after_destroy :decrement_user_caches

  class << self
    def define(user, discussion, options = {})
      relationship = find_or_initialize_by(
        user_id: user.id, discussion_id: discussion.id
      )
      relationship.assign_attributes(options)
      relationship.save
      relationship
    end
  end

  protected

  def favorite_or_following_enabled?
    (favorite_changed? && favorite?) ||
      (following_changed? && following?)
  end

  def ensure_flags_are_mutually_exclusive
    return unless hidden?

    if hidden_changed?
      # Unfollow if discussion has been hidden
      self.following = false
      self.favorite = false
    elsif favorite_or_following_enabled?
      # Unhide if discussion has been followed/favorited
      self.hidden = false
    end
  end

  def increment_user_caches
    deltas = FLAG_COUNTERS.each_with_object({}) do |(flag, counter), memo|
      memo[counter] = 1 if self[flag]
    end
    apply_user_deltas(deltas)
  end

  def decrement_user_caches
    deltas = FLAG_COUNTERS.each_with_object({}) do |(flag, counter), memo|
      memo[counter] = -1 if self[flag]
    end
    apply_user_deltas(deltas)
  end

  def sync_user_caches_on_change
    deltas = FLAG_COUNTERS.each_with_object({}) do |(flag, counter), memo|
      next unless saved_change_to_attribute?(flag)

      memo[counter] = self[flag] ? 1 : -1
    end
    apply_user_deltas(deltas)
  end

  def apply_user_deltas(deltas)
    return if deltas.empty?

    User.update_counters(user_id, deltas)
    deltas.each { |counter, delta| user.increment(counter, delta) } if user
  end
end
