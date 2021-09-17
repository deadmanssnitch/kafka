# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Error < ::Kafka::FFI::OpaquePointer
    # Initializes a new Error from a ResponseError code and optional human
    # readable message. You shouldn't need to initalize errors directly.
    #
    # @note This is primarily used to mock out errors while testing.
    #
    # @param code [Integer]
    # @param format [String]
    def self.new(code, format = nil, *values)
      # rd_kafka_error_new takes an optional printf style format and value
      # list. With FFI we would need to infer the types of each param in order
      # to pass it as a vararg. Instead it is formatted in Ruby and the final
      # string is passed as the human readable error message.
      human = nil

      # format is optional
      if format
        human = sprintf(format, *values)
      end

      ::Kafka::FFI.rd_kafka_error_new(code, human)
    end

    # Returns the RD_KAFKA_RESP_ERR_ code for the error.
    #
    # @return [Integer] error code for the error
    def code
      ::Kafka::FFI.rd_kafka_error_code(self)
    end

    # Returns the name for error
    #
    # @return [String] Error code name for the error
    def name
      ::Kafka::FFI.rd_kafka_error_name(self)
    end

    # Returns a human readable description of the error
    #
    # @return [String] human readable error description
    def string
      ::Kafka::FFI.rd_kafka_error_string(self)
    end
    alias to_s string

    # Indicates if the error was fatal indicating that the client is no longer
    # usable.
    #
    # @return [Boolean] True when the error is fatal
    def fatal?
      ::Kafka::FFI.rd_kafka_error_is_fatal(self)
    end

    # Indicates if the operation that errored can be retried.
    #
    # @return [Boolean] True when the operation can be retried
    def retriable?
      ::Kafka::FFI.rd_kafka_error_is_retriable(self)
    end

    # Alias Ruby style predicates to their librdkafka style method names.
    alias is_retriable retriable?
    alias is_fatal     fatal?

    # Returns true if the transaction error must be aborted by the client.
    #
    # @note Return value is only valid for errors returned by the transactional
    #   API.
    #
    # @return [Boolean] True when the transaction failed and the client must
    #   abort the transaction and start a new one.
    def txn_requires_abort
      ::Kafka::FFI.rd_kafka_error_txn_requires_abort(self)
    end
    alias txn_requires_abort? txn_requires_abort

    # Release the error and it's resources back to the system.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_error_destroy(self)
      end
    end
  end

  # TopicAlreadyConfigured is raised by Client#topic when passing a config to a
  # topic that has already been initialized for the Client.
  class TopicAlreadyConfiguredError < ::Kafka::Error; end

  # ConfigError is raised when making changes to the global config.
  class ConfigError < ::Kafka::Error
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
