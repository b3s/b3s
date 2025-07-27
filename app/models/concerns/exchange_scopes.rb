# frozen_string_literal: true

module ExchangeScopes
  extend ActiveSupport::Concern

  included do
    scope :sorted, -> { order("sticky DESC, last_post_at DESC") }
    scope :with_posters, -> { includes(:poster, :last_poster) }
    scope :for_view, -> { sorted.with_posters }
  end
end
