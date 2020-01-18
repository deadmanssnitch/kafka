# frozen_string_literal: true

module Kafka
  class Error < StandardError; end

  # ::Kafka::ResponseError is an Error that can be raised based on an :error_code as
  # returned from the librdkafka API.
  #
  # @see rdkafka.h RD_KAFKA_RESP_ERR_*
  # @see rdkafka.h rd_kafka_resp_err_t
  class ::Kafka::ResponseError < Error
    # @attr code [Integer] Error code as defined by librdkafka.
    attr_reader :code

    def initialize(code, message = nil)
      @code = code
      @message = message
    end

    # Returns the librdkafka error constant for this error.
    # @return [String]
    def name
      "RD_KAFKA_RESP_ERR_#{::Kafka::FFI.rd_kafka_err2name(@code)}"
    end

    # Returns true when the error is from internal to librdkafka or false when
    # the error was received from a broker or timeout.
    #
    # @see https://github.com/edenhill/librdkafka/blob/4818ecadee/src/rdkafka.h#L245
    #
    # @return [true] Error was internal to librdkafka
    # @return [false] Error was returned by the cluster
    def internal?
      code < 0
    end

    # Returns a human readable error description
    #
    # @return [String] Human readable description of the error.
    def to_s
      @message || ::Kafka::FFI.rd_kafka_err2str(@code)
    end
  end
end
