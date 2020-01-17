# frozen_string_literal: true

module Kafka::FFI
  class Error < Kafka::Error; end

  # TopicAlreadyConfigured is raised by Client#topic when passing a config to a
  # topic that has already been initialized for the Client.
  class TopicAlreadyConfiguredError < Error; end

  # ConfigError is raised when making changes to the global config.
  class ConfigError < Error
    attr_reader :key
    attr_reader :value

    def initialize(key, value, message)
      super(message)

      @key = key
      @value = value
    end
  end

  class UnknownConfigKey < ConfigError; end
  class InvalidConfigValue < ConfigError; end
end
