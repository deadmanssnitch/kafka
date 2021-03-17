# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class AdminOptions < ::Kafka::FFI::OpaquePointer
    def self.new(client, api)
      ::Kafka::FFI.rd_kafka_AdminOptions_new(client, api)
    end

    # rubocop:disable Naming/AccessorMethodName

    # Sets the overall request timeout which includes broker lookup, request
    # transmissing, operation time, and response processing.
    #
    # Valid for all admin requests.
    #
    # @note Default request timeout is `socket.timeout.ms` config option.
    #
    # @param timeout [-1] Wait indefinitely for request to finish
    # @param timeout [Integer] Time to wait in milliseconds for request to be
    #   processed.
    #
    # @raise [ResponseError<RD_KAFKA_RESP_ERR__INVALID_ARG>] Timeout was out of
    #   range.
    def set_request_timeout(timeout)
      error = ::FFI::MemoryPointer.new(:char, 512)

      resp = ::Kafka::FFI.rd_kafka_AdminOptions_set_request_timeout(self, timeout, error, error.size)
      if resp != :ok
        raise ::Kafka::ResponseError.new(resp, error.read_string)
      end

      nil
    ensure
      error.free
    end

    # Set the broker's operation wait timeout for the request to be processed
    # by the cluster.
    #
    # Only valid for :create_topics, :delete_topics, and :create_partitions
    # operations.
    #
    # @param timeout [-1, 0] Return immediately after starting the operation.
    # @param timeout [Integer] Max time to wait in milliseconds for the
    #   operation to propogate to the cluster.
    #
    # @raise [ResponseError<RD_KAFKA_RESP_ERR__INVALID_ARG>] Timeout was out of
    #   range.
    def set_operation_timeout(timeout)
      error = ::FFI::MemoryPointer.new(:char, 512)

      resp = ::Kafka::FFI.rd_kafka_AdminOptions_set_operation_timeout(self, timeout, error, error.size)
      if resp != :ok
        raise ::Kafka::ResponseError.new(resp, error.read_string)
      end

      nil
    ensure
      error.free
    end

    # Set an application object which will be available on the operation's
    # result event.
    #
    # @param opaque [Kafka::FFI::Opaque] Opaque object to store into the admin
    #   options.
    def set_opaque(opaque)
      if !opaque.is_a?(::Kafka::FFI::Opaque)
        raise ArgumentError, "opaque must be a Kafka::FFI::Opaque"
      end

      ::Kafka::FFI.rd_kafka_AdminOptions_set_opaque(self, opaque)
    end

    # Tell the broker to only validate the request without actually performing
    # the operation.
    #
    # Only valid for :create_topics, :delete_topics, and :create_partitions
    # operations.
    #
    # @param on [Boolean] True to validate the request without performing it.
    #
    # @raise [Kafka::ResponseError]
    def set_validate_only(on)
      error = ::FFI::MemoryPointer.new(:char, 512)

      resp = ::Kafka::FFI.rd_kafka_AdminOptions_set_validate_only(self, on, error, error.size)
      if resp != :ok
        raise ::Kafka::ResponseError.new(resp, error.read_string)
      end

      nil
    ensure
      error.free
    end

    # Override which broker the Admin request will be sent to. By default,
    # requests are sent to the controller Broker with a couple exceptions (see
    # librdkafka)
    #
    # @note This API shoudl typically not be used and primarily serves as a
    #   workaround in some cases.
    #
    # @see rdkafka.h rd_kafka_AdminOptions_set_broker
    #
    # @param broker_id [Integer] ID of the Broker to receive the request.
    def set_broker(broker_id)
      error = ::FFI::MemoryPointer.new(:char, 512)

      resp = ::Kafka::FFI.rd_kafka_AdminOptions_set_broker(self, broker_id, error, error.size)
      if resp != :ok
        raise ::Kafka::ResponseError.new(resp, error.read_string)
      end

      nil
    ensure
      error.free
    end

    # rubocop:enable Naming/AccessorMethodName

    # Ruby like aliases for librdkafka functions
    alias request_timeout= set_request_timeout
    alias operation_timeout= set_operation_timeout
    alias validate_only= set_validate_only
    alias broker= set_broker
    alias opaque= set_opaque

    def destroy
      ::Kafka::FFI.rd_kafka_AdminOptions_destroy(self)
    end
  end
end
