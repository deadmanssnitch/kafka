# frozen_string_literal: true

require "ffi"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class TopicResult < ::Kafka::FFI::OpaquePointer
    # Returns the name of the topic the result is for.
    #
    # @return [String] Topic name
    def name
      ::Kafka::FFI.rd_kafka_topic_result_name(self)
    end
    alias topic name

    # Returns either nil for success or an error with details about why the
    # topic operation failed.
    #
    # @return [nil] Topic operation was successful for this topic.
    # @return [Kafka::ResponseError] Error performing the operation for this
    #   topic.
    def error
      err = ::Kafka::FFI.rd_kafka_topic_result_error(self)
      if err != :ok
        ::Kafka::ResponseError.new(
          err,
          ::Kafka::FFI.rd_kafka_topic_result_error_string(self),
        )
      end
    end
  end
end
