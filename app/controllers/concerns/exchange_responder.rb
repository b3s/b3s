# frozen_string_literal: true

module ExchangeResponder
  extend ActiveSupport::Concern

  def respond_with_exchanges(exchanges)
    respond_to do |format|
      format.html { viewed_tracker.exchanges = exchanges }
      format.json { render json: ExchangeResource.new(exchanges) }
    end
  end

  def respond_with_exchange(exchange, page)
    respond_to do |format|
      format.html
      format.json do
        redirect_to(polymorphic_path([exchange, :posts], page:, format: :json))
      end
    end
  end
end
