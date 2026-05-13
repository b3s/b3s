# frozen_string_literal: true

class Discussion < Exchange
  class InvalidExchange < StandardError; end

  include SearchableExchange
  include Viewable

  has_many :discussion_relationships, dependent: :destroy

  scope :for_view, -> { sorted.with_posters }

  class << self
    def popular_in_the_last(days = 7.days)
      joins(:posts)
        .where("posts.created_at > ?", days.ago)
        .group("exchanges.id")
        .order(Arel.sql("COUNT(posts.id) DESC"))
    end
  end

  # Converts a discussion to a conversation
  def convert_to_conversation!
    raise InvalidExchange unless valid?

    transaction do
      update(type: "Conversation")
      becomes(Conversation).tap do |conversation|
        conversation.unlabel!
        posts.update_all(conversation: true)
        participants.each { |p| conversation.add_participant(p) }
        discussion_relationships.destroy_all
      end
    end
  end

  def participants
    User.find_by_sql(
      "SELECT u.*, MAX(p.created_at) AS last_post_at " \
      "FROM users u, posts p " \
      "WHERE p.exchange_id = #{id} AND p.user_id = u.id " \
      "GROUP BY u.id "
    )
  end

  def editable_by?(user)
    return false unless user
    return true if user.moderator?

    moderators.include?(user)
  end

  def postable_by?(user)
    return false unless user

    user.moderator? || !closed?
  end
end
