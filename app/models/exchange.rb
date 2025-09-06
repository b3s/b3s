# frozen_string_literal: true

# = Exchange
#
# Exchange is the base class for all threads, which both Discussion
# and Conversation inherit from.

class Exchange < ApplicationRecord
  include HumanizableParam
  include Paginatable
  include ExchangeScopes
  include VirtualBody

  self.per_page = 30

  attr_accessor :updated_by

  belongs_to(:poster, class_name: "User")
  belongs_to(:last_poster, class_name: "User", optional: true)

  belongs_to(:closer, class_name: "User", optional: true)

  has_many(:posts,
           -> { order :created_at },
           dependent: :destroy,
           foreign_key: "exchange_id",
           inverse_of: :exchange)

  has_many(:exchange_views,
           dependent: :destroy,
           inverse_of: :exchange)

  has_many(:users, through: :posts)

  has_many(:exchange_moderators, dependent: :destroy)

  has_many(:exchange_moderator_users,
           through: :exchange_moderators,
           source: :user)

  validates :title, presence: true, length: { maximum: 100 }
  validate :validate_closed

  def last_page(per_page = Post.per_page)
    (posts_count.to_f / per_page).ceil
  end

  def labels?
    closed? || sticky? || nsfw?
  end

  def labels
    labels = []
    labels << "Sticky"  if sticky?
    labels << "Closed"  if closed?
    labels << "NSFW"    if nsfw?
    labels
  end

  def moderators
    ([poster] + exchange_moderator_users).uniq
  end

  def moderators?
    exchange_moderators.any?
  end

  def to_param
    humanized_param(title)
  end

  def closeable_by?(user)
    return false unless user
    return true if user.moderator?
    return false if closer && moderators.exclude?(closer)

    moderators.include?(user)
  end

  def unlabel!
    update(
      sticky: false,
      closed: false,
      nsfw: false
    )
  end

  private

  def validate_closed
    return unless closed_changed?

    if !closed? && (!updated_by || !closeable_by?(updated_by))
      errors.add(:closed, "can't be changed!")
    elsif closed?
      self.closer = updated_by
    else
      self.closer = nil
    end
  end
end
