# frozen_string_literal: true

# = ConversationRelationship

# Models the relationship between conversations and users.

class ConversationRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :conversation
  validates :user_id, uniqueness: { scope: :conversation_id }
  after_destroy_commit :disconnect_cable_connections

  private

  def disconnect_cable_connections
    ActionCable.server.remote_connections.where(current_user: user).disconnect
  end
end
