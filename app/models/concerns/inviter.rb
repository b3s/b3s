# frozen_string_literal: true

module Inviter
  extend ActiveSupport::Concern

  attr_accessor :invite

  included do
    before_create :set_inviter
    after_create :expire_invite

    belongs_to :inviter,
               class_name: "User",
               optional: true

    has_many :invitees,
             -> { order :username },
             class_name: "User",
             foreign_key: "inviter_id",
             inverse_of: :inviter,
             dependent: :nullify

    has_many :invites,
             -> { order :created_at },
             dependent: :destroy,
             inverse_of: :user
  end

  def invites?
    invites.any?
  end

  def invitees?
    invitees.any?
  end

  def invites_or_invitees?
    invites? || invitees?
  end

  def available_invites?
    user_admin? || available_invites.positive?
  end

  # Number of remaining invites. User admins always have at least one invite.
  def available_invites
    user_admin? ? 1 : self[:available_invites]
  end

  # Revokes invites from a user, default = 1.
  # Pass :all as an argument to revoke all invites.
  def revoke_invite!(number = 1)
    return available_invites if user_admin?

    number = available_invites if number == :all
    new_invites = available_invites - number
    new_invites = 0 if new_invites.negative?
    update(available_invites: new_invites)
    available_invites
  end

  def grant_invite!(number = 1)
    return available_invites if user_admin?

    new_number = (available_invites + number)
    update(available_invites: new_number)
    invites
  end

  protected

  def set_inviter
    self.inviter = invite.user if invite
  end

  def expire_invite
    invite&.expire!
  end
end
