# frozen_string_literal: true

module PreprocessablePost
  extend ActiveSupport::Concern

  MAX_BODY_LENGTH = 100_000

  included do
    attr_accessor :skip_preprocess

    validates :body, length: { maximum: MAX_BODY_LENGTH }, if: :body_changed?
  end

  def preprocess!
    return self if skip_preprocess || body_too_long?

    fetch_budget = FetchBudget.new
    fetch_images(fetch_budget)
    self.body_html = Renderer.render(body, format:, fetch_budget:)
    self.skip_preprocess = true
    self
  end

  def body_too_long?
    body.to_s.length > MAX_BODY_LENGTH
  end

  private

  def fetch_images(fetch_budget)
    self.body = ImageFetcher.fetch(body, fetch_budget:)
  end
end
