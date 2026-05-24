# frozen_string_literal: true

class ExchangeChannel < ApplicationCable::Channel
  def subscribed
    exchange = Exchange.find_by(id: params[:id])
    return reject unless exchange&.viewable_by?(current_user)

    stream_for exchange
  end
end
