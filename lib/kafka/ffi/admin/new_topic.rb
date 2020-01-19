# frozen_string_literal: true

require "kafka/ffi/error"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class NewTopic < ::Kafka::FFI::OpaquePointer
    # Create a new NewTopic for passing to Admin::Client#create_topics. It is
    # the application's responsiblity to call #destroy when done with the
    # object.
    #
    # @param name [String] Name of the topic to create
    # @param partitions [Integer] Number of partitions in the topic
    #
    # @param replication_factor [Integer] Default replication factor for the
    #   topic's partitions.
    # @param replication_factor [-1] Value from #set_replica_assignment will be
    #   used.
    #
    # @raise [ArgumentError] Parameters were invalid
    #
    # @return [NewTopic]
    def self.new(name, partitions, replication_factor)
      # Allocate memory for the error message
      error = ::FFI::MemoryPointer.new(:char, 512)

      if name.nil? || name.empty?
        raise ArgumentError, " name is required and cannot be blank"
      end

      obj = ::Kafka::FFI.rd_kafka_NewTopic_new(name, partitions, replication_factor, error, error.size)
      if obj.nil?
        raise ArgumentError, error.read_string
      end

      obj
    ensure
      error.free
    end

    # Set the broker assignment for partition to the replica set in broker_ids.
    #
    # @note If called, must be call consecutively for each partition, starting
    #   at 0.
    # @note new must have been called with replication_factor of -1
    #
    # @param partition [Integer] Partition to assign to the brokers
    # @param broker_ids [Integer, Array<Integer>] Brokers that will be assigned
    #   the partition for the topic.
    #
    # @raise [Kafka::ResponseError] Error occurred setting config
    def set_replica_assignment(partition, broker_ids)
      broker_ids = Array(broker_ids)

      brokers = ::FFI::MemoryPointer.new(:int32, broker_ids.size)
      error   = ::FFI::MemoryPointer.new(:char, 512)

      brokers.write_array_of_int32(broker_ids)

      err = ::Kafka::FFI.rd_kafka_NewTopic_set_replica_assignment(self, partition, brokers, broker_ids.size, error, error.size)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      nil
    ensure
      error.free
      brokers.free
    end

    # Set the broker side topic configuration name/value pair.
    #
    # @raise [Kafka::ResponseError] Arguments were invalid
    def set_config(name, value)
      err = ::Kafka::FFI.rd_kafka_NewTopic_set_config(self, name, value)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      nil
    end

    # Release the memory held by NewTopic back to the system. This must be
    # called by the application when it is done with the object.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_NewTopic_destroy(self)
      end
    end
  end
end
