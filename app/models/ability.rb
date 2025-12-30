# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Guests have no abilities - authentication required for everything
    return if user.nil?

    # Base authenticated user abilities
    authenticated_abilities(user)

    # Role-based abilities (cascading)
    user_admin_abilities(user) if user.user_admin?
    moderator_abilities(user) if user.moderator?
    admin_abilities(user) if user.admin?
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def authenticated_abilities(user)
    # Users
    can :read, User
    can :update, User, id: user.id

    # Discussions
    can :read, Discussion
    can :create, Discussion

    # Discussion ownership and moderator abilities
    can :update, Discussion, poster_id: user.id
    can :update, Discussion, exchange_moderators: { user_id: user.id }

    # Close discussions (poster or exchange moderator)
    can :close, Discussion, poster_id: user.id
    can :close, Discussion, exchange_moderators: { user_id: user.id }

    # Conversations - participant-based access
    can :read, Conversation do |conversation|
      conversation.participants.include?(user)
    end
    can :create, Conversation
    can :update, Conversation, poster_id: user.id
    can :update, Conversation, exchange_moderators: { user_id: user.id }

    # Posts
    can :read, Post
    can :update, Post, user_id: user.id

    # Creating posts - complex logic requires block
    can :create, Post do |post|
      if post.exchange.is_a?(Discussion)
        # Can post to discussions if not closed
        !post.exchange.closed?
      elsif post.exchange.is_a?(Conversation)
        # Can post to conversations if participant
        post.exchange.conversation_relationships.exists?(user_id: user.id)
      else
        false
      end
    end

    # Invites
    can :manage, Invite, user_id: user.id
    can :accept, Invite # Anyone can accept an invite

    # Discussion relationships (following, favoriting, hiding)
    can :manage, DiscussionRelationship, user_id: user.id

    # Conversation participants
    can :create, ConversationRelationship do |relationship|
      # Only conversation participants can add new participants
      relationship.conversation.participants.include?(user)
    end

    can :destroy, ConversationRelationship do |relationship|
      # Users can remove themselves or be removed by conversation poster
      relationship.user_id == user.id ||
        relationship.conversation.poster_id == user.id
    end

    # Uploads (PostImages)
    can :create, PostImage
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def moderator_abilities(_user)
    # Moderators can update any discussion or post
    can :update, Discussion
    can :update, Post
    can :close, Discussion

    # Moderators can post to closed discussions
    can :create, Post do |post|
      post.exchange.is_a?(Discussion)
    end

    # Moderators can manage conversation participants
    can :manage, ConversationRelationship
  end

  def user_admin_abilities(_user)
    # User admins can manage all users and invites
    can :manage, User
    can :manage, Invite
  end

  def admin_abilities(_user)
    # Admins can do everything
    can :manage, :all
  end
end
