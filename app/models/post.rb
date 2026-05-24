# frozen_string_literal: true

class Post < ApplicationRecord
  include ConversationPost
  include SearchablePost
  include Paginatable
  include Viewable

  self.per_page = 50

  belongs_to :user, counter_cache: true, touch: true
  belongs_to :exchange, counter_cache: true, touch: true
  has_many :exchange_views, dependent: :restrict_with_exception

  acts_as_list scope: :exchange, add_new_at: :bottom

  validates :body, presence: true
  validates :format, inclusion: %w[markdown html]

  attr_accessor :skip_html

  before_save :fetch_images,
              :set_edit_timestamp,
              :render_html

  after_create :update_exchange,
               :define_relationship,
               :increment_public_posts_count

  after_destroy :decrement_public_posts_count

  after_commit :broadcast_count, on: :create

  scope :sorted,                 -> { order(:created_at) }
  scope :for_view,               -> { sorted.includes(user: [:avatar]) }
  scope :for_view_with_exchange, -> { for_view.includes(exchange: :poster) }

  def me_post?
    body.strip =~ %r{^/me} && body.exclude?("\n")
  end

  def post_number
    @post_number ||= exchange.posts.where(id: ...id).count + 1
  end

  def page(options = {})
    (post_number.to_f / (options[:limit] || Post.per_page)).ceil
  end

  def body_html
    if new_record? || Rails.env.development?
      Renderer.render(body, format:)
    else
      update_column(:body_html, Renderer.render(body, format:)) if super.blank?
      self[:body_html].html_safe
    end
  end

  def edited?
    return false unless edited_at?

    ((edited_at || created_at) - created_at) > 60.seconds
  end

  def editable_by?(user)
    user.present? && (user.moderator? || user == self.user)
  end

  def fetch_images
    self.body = ImageFetcher.fetch(body) unless skip_html
  end

  def mentions_users?
    mentioned_users.any?
  end

  def mentioned_users
    @mentioned_users ||= User.all.select do |user|
      user_expression = Regexp.new("@#{Regexp.quote(user.username)}",
                                   Regexp::IGNORECASE)
      body.match?(user_expression)
    end
  end

  private

  # Falls back to posts_count so new posts don't collide with the
  # in-progress ROW_NUMBER backfill of NULL positions.
  def bottom_position_in_list(except = nil)
    item = bottom_item(except)
    item ? item.current_position : (exchange&.posts_count || 0)
  end

  def increment_public_posts_count
    return if conversation?

    User.update_counters(user_id, public_posts_count: 1)
    user.increment(:public_posts_count)
  end

  def decrement_public_posts_count
    return if conversation?

    User.update_counters(user_id, public_posts_count: -1)
    user.decrement(:public_posts_count)
  end

  def render_html
    self.body_html = Renderer.render(body, format:) unless skip_html
  end

  def set_edit_timestamp
    self.edited_at ||= Time.now.utc
  end

  def define_relationship
    return if conversation?

    DiscussionRelationship.define(user, exchange, participated: true)
  end

  def update_exchange
    exchange.update(
      last_poster_id: user.id,
      last_post_at: created_at
    )
  end

  def broadcast_count
    ExchangeChannel.broadcast_to(exchange, posts_count: exchange.posts_count)
  end
end
