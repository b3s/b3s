# frozen_string_literal: true

module ConfigurationMacros
  def configure(configuration = {})
    B3S.config.update(configuration)
  end
end
