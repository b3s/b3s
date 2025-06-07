# frozen_string_literal: true

Rails.application.configure do
  MissionControl::Jobs.base_controller_class = "AdminController"
  MissionControl::Jobs.http_basic_auth_enabled = false
end
