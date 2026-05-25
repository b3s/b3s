# frozen_string_literal: true

class ExchangeChannel < ApplicationCable::Channel
  def subscribed
    return reject unless exchange&.viewable_by?(current_user)

    stream_for exchange
  end

  def viewed(data)
    post = exchange&.posts&.find_by(id: data["post_id"])
    return unless post

    current_user.mark_exchange_viewed(exchange, post, data["index"].to_i)
    current_user.mark_conversation_viewed(exchange) if exchange.is_a?(Conversation)
  end

  private

  def exchange
    return @exchange if defined?(@exchange)

    @exchange = Exchange.find_by(id: params[:id])
  end
end
