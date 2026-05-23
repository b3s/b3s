# frozen_string_literal: true

module QueryCounter
  def count_queries(matching: nil)
    count = 0
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if matching && payload[:sql].exclude?(matching)

      count += 1
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
  end
end
