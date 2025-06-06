# frozen_string_literal: true

require "digest/sha1"

# = User accounts
#

class User < ApplicationRecord
  include Authenticable
  include Inviter
  include Emailable
  include ExchangeParticipant
  include HasMutedUsers
  include UserScopes

  belongs_to :avatar, dependent: :destroy, optional: true
  has_many :exchange_moderators, dependent: :destroy
  has_many :user_links, dependent: :destroy
  accepts_nested_attributes_for :avatar
  accepts_nested_attributes_for :user_links, allow_destroy: true
  validates_associated :avatar

  before_validation :ensure_last_active_is_set
  before_create :check_for_first_user
  before_update :check_username_change

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[^?]+\Z/ }

  validates :stylesheet_url, url: { allow_blank: true }
  validates :mobile_stylesheet_url, url: { allow_blank: true }

  def name_and_email
    realname? ? "#{realname} <#{email}>" : email
  end

  def realname_or_username
    realname? ? realname : username
  end

  def online?
    last_active && last_active > 15.minutes.ago
  end

  def user_admin?
    self[:user_admin] || admin?
  end

  def moderator?
    self[:moderator] || admin?
  end

  def previous_usernames
    (self[:previous_usernames] || "").split("\n")
  end

  # Returns admin flags as strings
  def admin_labels
    labels = []
    if admin?
      labels << "Admin"
    else
      labels << "User Admin" if user_admin?
      labels << "Moderator" if moderator?
    end
    labels
  end

  def theme
    super || B3S.config.default_theme
  end

  def mark_active!
    return if last_active && last_active > 10.minutes.ago

    update(last_active: Time.now.utc)
  end

  def mobile_theme
    super || B3S.config.default_mobile_theme
  end

  def serializable_params
    %i[id username realname latitude longitude inviter_id last_active created_at
       description admin moderator user_admin location banned_until]
  end

  def serializable_methods
    %i[status]
  end

  def as_json(options = {})
    super({ only: serializable_params,
            methods: serializable_methods }.merge(options))
  end

  protected

  def ensure_last_active_is_set
    self.last_active ||= Time.now.utc
  end

  def check_for_first_user
    self.admin = true unless User.any?
  end

  def check_username_change
    return unless username_changed?

    self[:previous_usernames] = ([username_was] + previous_usernames).join("\n")
  end
end
