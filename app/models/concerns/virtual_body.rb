# frozen_string_literal: true

module VirtualBody
  extend ActiveSupport::Concern

  included do
    attr_accessor :body, :format

    after_create :create_first_post
    after_update :update_post_body
    validates :body, presence: true, on: :create
    validates :body, length: { maximum: Post::MAX_BODY_LENGTH }, if: :body_edited?
  end

  private

  def body_edited?
    new_record? || body != posts.first&.body
  end

  def create_first_post
    return if body.blank?

    attributes = {
      user: poster,
      body:
    }
    attributes[:format] = format if format.present?
    posts.create(attributes)
  end

  def format_options
    return {} if format.blank?

    { format: }
  end

  def post_attributes
    {
      edited_at: Time.now.utc,
      body:
    }.merge(format_options)
  end

  def update_post_body
    return unless body.present? && body != posts.first.body

    posts.first.update(post_attributes)
  end
end
