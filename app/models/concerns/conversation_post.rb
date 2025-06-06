# frozen_string_literal: true

module ConversationPost
  extend ActiveSupport::Concern

  included do
    before_save :flag_conversation
    after_create :notify_new_conversation_post
  end

  private

  def flag_conversation
    self.conversation = exchange.is_a?(Conversation)
  end

  def notify_new_conversation_post
    return unless conversation?

    exchange.conversation_relationships.each do |relationship|
      relationship.update(new_posts: true) unless relationship.user == user
    end
  end
end
