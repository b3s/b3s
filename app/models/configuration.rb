# frozen_string_literal: true

class Configuration
  class InvalidConfigurationKey < StandardError; end

  include ActiveModel::Model

  Parameter = Struct.new(:type, :default)

  class << self
    def parameters
      @parameters ||= {}
    end

    def parameter(key, type, default = nil)
      define_accessors(key)
      parameters[key] = Parameter.new(type, default)
    end

    private

    def define_accessors(key)
      define_method key do
        get(key)
      end
      define_method :"#{key}?" do
        get(key) ? true : false
      end
      define_method :"#{key}=" do |value|
        set(key, value)
      end
    end
  end

  include Parameters

  def get(key)
    validate_parameter(key)
    if configuration.key?(key)
      configuration[key]
    else
      self.class.parameters[key].default
    end
  end

  def set(key, value)
    key = key.to_sym if key.is_a?(String)
    validate_parameter(key)
    validate_type(key, value)
    value = parse_value(key, value)
    configuration[key] = value
  end

  def load
    @configuration = Setting.all.to_h do |setting|
      [setting.name.to_sym, setting.value]
    end
  end

  def save
    @configuration.each do |name, value|
      Setting.find_or_initialize_by(name:).update(value:)
    end
  end

  def update(attributes = {})
    attributes.each { |key, value| set(key, value) }
    save
  end

  def reset!
    @configuration = {}
  end

  protected

  def configuration
    @configuration ||= {}
  end

  def parameter?(key)
    self.class.parameters.key?(key)
  end

  def type_for(key)
    self.class.parameters[key].type
  end

  def valid_type?(key, value)
    return true if value.nil?

    if type_for(key) == :boolean
      value.is_a?(TrueClass) || value.is_a?(FalseClass)
    else
      value.is_a?(type_for(key).to_s.camelize.constantize)
    end
  end

  def validate_parameter(key)
    return if parameter?(key)

    raise(InvalidConfigurationKey, ":#{key} is not a valid option")
  end

  def validate_type(key, value)
    return if valid_type?(key, parse_value(key, value))

    raise(ArgumentError, "expected #{self.class.parameters[key].type}, " \
                         "got #{value.class} (#{value.inspect})")
  end

  def parse_value(key, value)
    if type_for(key) == :boolean
      if ["1", "true", :enabled].include?(value)
        value = true
      elsif ["0", "false", :disabled].include?(value)
        value = false
      end
    end
    value
  end
end
