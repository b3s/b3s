# frozen_string_literal: true

module Authenticable
  extend ActiveSupport::Concern

  included do
    has_secure_password

    generates_token_for :password_reset, expires_in: 2.hours do
      password_reset_fingerprint
    end

    before_validation :go_on_hiatus
    before_validation :clear_banned_until
    after_save :schedule_reactivation_job

    attribute :hiatus_until, :datetime

    enum :status, { active: 0, inactive: 1, hiatus: 2, time_out: 3, banned: 4,
                    memorialized: 5 }

    validate :verify_banned_until
    validates(
      :password,
      length: {
        minimum: 8,
        maximum: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED,
        allow_blank: true
      }
    )
    validates :password, presence: true, unless: -> { password.nil? }

    after_initialize do |u|
      u.persistence_token ||= u.class.random_persistence_token
    end

    before_validation :update_persistence_token
    after_update_commit :disconnect_cable_connections, if: :access_changed?
  end

  module ClassMethods
    def find_and_authenticate_with_password(email, password)
      User.authenticate_by(email: email.to_s, password: password.to_s)
    end

    def random_persistence_token
      SecureRandom.hex(32)
    end
  end

  def deactivated?
    !active?
  end

  def temporary_banned?
    banned_until? && banned_until > Time.now.utc
  end

  def log_out_everywhere!
    self.persistence_token = self.class.random_persistence_token
    save!(validate: false)
  end

  def require_password_challenge
    if email.presence != email_was.presence || password_digest_changed?
      self.password_challenge ||= ""
    else
      self.password_challenge = nil
    end
  end

  def reactivate_if_eligible!
    return unless hiatus? || time_out?
    return if banned_until && banned_until > Time.now.utc

    update(status: :active)
  end

  protected

  def password_reset_fingerprint
    key = Rails.application.key_generator.generate_key("password_reset_fingerprint")
    OpenSSL::HMAC.hexdigest("SHA256", key, [email, password_digest].to_json).last(16)
  end

  def clear_banned_until
    self.banned_until = nil if banned_until? && banned_until <= Time.now.utc
  end

  def go_on_hiatus
    return unless hiatus_until && hiatus_until > Time.now.utc

    self.status = :hiatus
    self.banned_until = hiatus_until
  end

  def verify_banned_until
    return unless hiatus? || time_out?
    return if banned_until?

    errors.add(:banned_until, "is required")
  end

  def update_persistence_token
    return unless password_digest_changed?

    self.persistence_token = self.class.random_persistence_token
  end

  def access_changed?
    saved_change_to_status? || saved_change_to_persistence_token?
  end

  def disconnect_cable_connections
    ActionCable.server.remote_connections.where(current_user: self).disconnect
  end

  def schedule_reactivation_job
    return unless saved_change_to_status? || saved_change_to_banned_until?
    return unless (hiatus? || time_out?) && temporary_banned?

    ReactivateUserJob.set(wait_until: banned_until + 5.minutes)
                     .perform_later(id)
  end
end
