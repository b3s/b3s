# frozen_string_literal: true

module Admin
  class ConfigurationsController < AdminController
    before_action :find_configuration

    def show
      redirect_to edit_admin_configuration_url
    end

    def edit; end

    def update
      @configuration.update(configuration_params) if configuration_params
      redirect_to edit_admin_configuration_url
    end

    protected

    def configuration_params
      params[:configuration]
    end

    def find_configuration
      @configuration = B3S.config
    end
  end
end
