# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class NewPartitions < ::Kafka::FFI::OpaquePointer
    # Allocates a new NewPartitions request for passing to CreatePartitions to
    # increase the number of partitions for an existing topic.
    #
    # @param topic [String] Name of the topic to adjust
    # @param partition_count [Integer] Increase the number of partitions to
    #   this value.
    #
    # @raise [ArgumentError] Invalid topic or partition_count
    def self.new(topic, partition_count)
      error = ::FFI::MemoryPointer.new(:char, 512)

      if topic.nil? || topic.empty?
        # Check in Ruby as nil will cause a segfault as of 1.3.0
        raise ArgumentError, "topic name is required"
      end

      req = ::Kafka::FFI.rd_kafka_NewPartitions_new(topic, partition_count, error, error.size)
      if req.nil?
        raise ArgumentError, error.read_string
      end

      req
    ensure
      error.free
    end

    # Assign the partition by index, relative to existing partition count, to
    # be replicated on the set of brokers specified by broker_ids. If called,
    # this method must be called consecutively for each new partition being
    # created starting with an index of 0.
    #
    # @note This MUST either be called for all new partitions or not at all.
    #
    # @example Assigning broker assignments for two new partitions
    #   # Topic already has 3 partitions and replication factor of 2.
    #   request = NewPartitions("topic", 5)
    #   request.set_replica_assignment(0, [1001, 1003])
    #   request.set_replica_assignment(1, [1002, 1001])
    #
    # @param partition_index [Integer] Index of the new partition being
    #   created.
    # @param broker_ids [Array<Integer>] Broker IDs to be assigned a replica of
    #   the topic. Number of broker ids should match the topic replication
    #   factor.
    #
    # @raise [Kafka::ResponseError] Arguments were invalid or partition_index
    #   was not called consecutively.
    def set_replica_assignment(partition_index, broker_ids)
      error = ::FFI::MemoryPointer.new(:char, 512)

      broker_list = ::FFI::MemoryPointer.new(:int32, broker_ids.length)
      broker_list.write_array_of_int32(broker_ids)

      resp = ::Kafka::FFI.rd_kafka_NewPartitions_set_replica_assignment(self, partition_index, broker_list, broker_ids.length, error, error.size)
      if resp != :ok
        raise ::Kafka::ResponseError.new(resp, error.read_string)
      end

      nil
    ensure
      error.free
    end

    # Destroy and free the NewPartitions, releasing it's resources back to the
    # system.
    def destroy
      ::Kafka::FFI.rd_kafka_NewPartitions_destroy(self)
    end
  end
end

