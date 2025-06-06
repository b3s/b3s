# frozen_string_literal: true

class Post < ApplicationRecord
  include ConversationPost
  include SearchablePost
  include Paginatable
  include Viewable

  self.per_page = 50

  belongs_to :user, touch: true
  belongs_to :exchange, touch: true
  has_many :exchange_views, dependent: :restrict_with_exception

  validates :body, presence: true
  validates :format, inclusion: %w[markdown html]

  attr_accessor :skip_html

  before_save :fetch_images,
              :set_edit_timestamp,
              :render_html

  after_create :update_exchange,
               :define_relationship,
               :update_post_counts

  after_destroy :update_post_counts

  scope :sorted,                 -> { order("created_at ASC") }
  scope :for_view,               -> { sorted.includes(user: [:avatar]) }
  scope :for_view_with_exchange, -> { for_view.includes(:exchange) }

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

  def update_post_counts
    exchange.update(posts_count: exchange.posts.count)
    user.update(
      posts_count: user.posts.count,
      public_posts_count: user.discussion_posts.count
    )
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
end
