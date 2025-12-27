# frozen_string_literal: true

require "digest/md5"

class ApplicationController < ActionController::Base
  include Authentication
  include ExchangeResponder
  include ViewedTrackerHelper

  layout "application"

  protect_from_forgery with: :exception

  before_action :load_configuration
  before_action :set_time_zone
  before_action :set_section
  before_action :set_sentry_context
  before_action :set_variant

  helper_method :current_section, :mobile_user_agent?, :theme, :mobile_theme,
                :search_query

  protected

  def current_section
    params[:controller].to_sym
  end

  def current_user_context
    return {} unless current_user?

    { id: current_user.id, username: current_user.username }
  end

  # Renders an error
  def render_error(error, options = {})
    options[:status] ||= error if error.is_a?(Numeric)
    respond_to do |format|
      format.html { options[:template] ||= "errors/#{error}" }
      format.json { options[:text] ||= error_messages[error] }
    end
    render options
  end

  def load_configuration
    B3S.config.load
  end

  def set_time_zone
    Time.zone = current_user.time_zone if current_user.try(&:time_zone)
  end

  def mobile_user_agent?
    request.host =~ /^(iphone|m|mobile)\./ ||
      (request.env["HTTP_USER_AGENT"] &&
      request.env["HTTP_USER_AGENT"][%r{(Mobile/.+Safari|Android|IEMobile)}])
  end

  def mobile_variant?
    return false unless mobile_user_agent?

    session[:mobile_format] = params[:mobile_format] ||
                              session[:mobile_format] ||
                              "mobile"

    session[:mobile_format] == "mobile" && request.format == "text/html"
  end

  def set_sentry_context
    Sentry.set_user(current_user_context)
    Sentry.set_extras(params: params.to_unsafe_h)
  end

  def set_section
    mapping = {
      Users::ListsController => :users,
      Users::ProfilesController => :users,
      InvitesController => :invites,
      ConversationsController => :conversations
    }
    mapping[self.class] || :discussions
  end

  def set_variant
    request.variant = :mobile if mobile_variant?
  end

  def mobile_theme
    Theme.find(current_user&.mobile_theme || B3S.config.default_mobile_theme)
  end

  def theme
    Theme.find(current_user&.theme || B3S.config.default_theme)
  end

  def search_query
    params[:q]
  end
end
