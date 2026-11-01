# frozen_string_literal: true

class UserLink < ApplicationRecord
  URL_PATTERN = %r{\A(?:https?://)?(?<host>[a-zA-Z0-9\-.]+)(?:/\S*)?\z}

  belongs_to :user

  validates :label, presence: true
  validates :url,
            presence: { unless: :name? },
            format: { with: URL_PATTERN, allow_blank: true }
  validate :validate_url_domain

  acts_as_list scope: :user

  scope :sorted, -> { order(:position) }

  class << self
    def active
      joins(:user).where(user: { status: %i[active memorialized] })
    end

    def labels
      active.pluck(:label).sort.uniq(&:downcase)
    end

    def with_label(label)
      where("lower(label) LIKE lower(?)", label)
    end
  end

  def label=(new_label)
    super(new_label&.strip)
  end

  def name=(new_name)
    super(new_name&.strip)
  end

  def url=(new_url)
    super(new_url&.strip)
  end

  def name_or_pretty_url
    return name if name?

    url.gsub(%r{^(f|ht)tps?://}, "")
  end

  private

  def url_host
    host = URL_PATTERN.match(url.to_s)&.[](:host)
    host && Addressable::IDNA.to_unicode(host.downcase)
  end

  def validate_url_domain
    host = url_host
    return if host.nil? || PublicSuffix.valid?(host, default_rule: nil)

    errors.add(:url, :invalid_domain)
  end
end
