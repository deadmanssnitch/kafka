# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  # GroupResult is returned by group commands to the Admin API.
  class GroupResult < ::Kafka::FFI::OpaquePointer
    # Returns the error from the command or nil if the command was successful.
    #
    # @return [Error, nil] Error that occurred from the command or nil if the
    #   command was successful.
    def error
      ::Kafka::FFI.rd_kafka_group_result_error(self)
    end

    # Returns true when the command errored and #error should be checked.
    #
    # @see #error
    #
    # @return [Boolean] True when an error occurred or false if the command
    #   succeeded.
    def error?
      !error.nil?
    end

    # Returns true when the command completed successfully without an error.
    #
    # @return [Boolean] True when the command completed without an error.
    def successful?
      !error?
    end

    # Returns the name of the group that result is for.
    #
    # @return [String] Name of the consumer group
    def name
      ::Kafka::FFI.rd_kafka_group_result_name(self)
    end

    # Returns the list of affected or requested topic and partitions pairs or
    # nil when not applicable.
    #
    # @return [Kafka::FFI::TopicPartitionList, nil] Topic partition pairs that
    #   were affected or nil when not applicable.
    def partitions
      tpl = ::Kafka::FFI.rd_kafka_group_result_partitions(self)
      tpl.null? ? nil : tpl
    end
  end
end
