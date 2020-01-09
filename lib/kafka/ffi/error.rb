# frozen_string_literal: true

module Kafka::FFI
  class Error < Kafka::Error; end

  # TopicAlreadyConfigured is raised by Client#topic when passing a config to a
  # topic that has already been initialized for the Client.
  class TopicAlreadyConfiguredError < Error; end

  # ResponseError is an Error that can be raised based on an :error_code as
  # returned from the librdkafka API.
  #
  # @see rdkafka.h RD_KAFKA_RESP_ERR_*
  # @see rdkafka.h rd_kafka_resp_err_t
  class ResponseError < Error
    attr_reader :code

    def initialize(code)
      @code = code
    end

    def name
      "RD_KAFKA_RESP_ERR_#{::Kafka::FFI.rd_kafka_err2name(@code)}"
    end

    def to_s
      ::Kafka::FFI.rd_kafka_err2str(@code)
    end
  end

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
