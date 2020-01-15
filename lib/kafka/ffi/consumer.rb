# frozen_string_literal: true

require "ffi"
require "kafka/ffi/client"

module Kafka::FFI
  class Consumer < Kafka::FFI::Client
    native_type :pointer

    def self.new(config = nil)
      super(:consumer, config)
    end

    # Retrieve the Consumer's broker assigned group Member ID.
    #
    # @return [String] broker assigned group Member ID
    def member_id
      id = ::Kafka::FFI.rd_kafka_memberid(self)

      if id.null?
        return nil
      end

      id.read_string
    ensure
      ::Kafka::FFI.rd_kafka_mem_free(self, id)
    end

    # Get the last known (cached) low and high offsets for the partition. This
    # differs from query_watermark_offsets in that does not query the brokers.
    #
    # @see query_watermark_offsets
    #
    # @param topic [String] Name of the topic
    # @param partition [Integer] Topic partition
    #
    # @raise [ResponseError] Error that occurred retrieving offsets
    #
    # @return [Array<(Integer, Integer)>] low and high offsets. If either is
    #   unknown the RD_KAFKA_OFFSET_INVALID is returned for that value
    def get_watermark_offsets(topic, partition)
      low  = ::FFI::MemoryPointer.new(:int64)
      high = ::FFI::MemoryPointer.new(:int64)

      err = ::Kafka::FFI.rd_kafka_get_watermark_offsets(self, topic, partition, low, high)
      if err != :ok
        raise ResponseError, err
      end

      [low.read_int64, high.read_int64]
    end

    # rubocop:disable Naming/AccessorMethodName

    # Returns a reference to the consume queue. This is the queue served by
    # consumer_poll.
    #
    # @note Caller must call #destroy when done with the Queue.
    #
    # @return [Queue] Consumer queue
    def get_consumer_queue
      ::Kafka::FFI.rd_kafka_queue_get_consumer(self)
    end
    # rubocop:enable Naming/AccessorMethodName

    # Returns a reference to the partition's queue.
    #
    # @note Caller must call #destroy when done with the Queue.
    #
    # @return [Queue] Partition Queue
    def get_partition_queue(topic, partition)
      ::Kafka::FFI.rd_kafka_queue_get_partition(self, topic, partition)
    end

    # Redirect the main event queue to the Consumer's queue so the consumer
    # doesn't need to poll from it separately for event callbacks to fire.
    #
    # @note It is not permitted to call #poll after redirecting the main queue
    #   with poll_set_consumer.
    #
    # @raise [ResponseError] Error occurred redirecting the main queue.
    def poll_set_consumer
      err = ::Kafka::FFI.rd_kafka_poll_set_consumer(self)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # Subscribe the consumer to receive Messages for a set of topics. The given
    # list is still owned by the caller and it is the caller's responsibility
    # to destroy it when appropriate.
    #
    # @param list [TopicPartitionList] List of Topic + Partitions to subscribe
    #   to.
    #
    # @raise [ResponseError] Error occurred subscribing to the topic.
    def subscribe(list)
      err = ::Kafka::FFI.rd_kafka_subscribe(self, list)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # Unsubscribe from the current subscription set (e.g. all current
    # subscriptions).
    #
    # @raise [ResponseError] Error unsubscribing from topics
    def unsubscribe
      err = ::Kafka::FFI.rd_kafka_unsubscribe(self)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # List the current topic subscriptions for the consumer.
    #
    # @raise [ResponseError] Error that occurred retrieving the subscriptions
    #
    # @return [TopicPartitionList] List of current subscriptions
    def subscription
      ptr = ::FFI::MemoryPointer.new(:pointer)

      resp = ::Kafka::FFI.rd_kafka_subscription(self, ptr)
      if resp != :ok
        raise ResponseError, resp
      end

      ::Kafka::FFI::TopicPartitionList.new(ptr.read_pointer)
    ensure
      ptr.free
    end

    # Atomically assign the set of partitions to consume. This will replace the
    # existing assignment.
    #
    # @see rdkafka.h rd_kafka_assign for semantics on use from callbacks and
    #   how empty vs NULL lists affect internal state.
    #
    # @param list [TopicPartitionList] List of topic+partition assignments
    #
    # @raise [ResponseError] Error processing assignments
    def assign(list)
      err = ::Kafka::FFI.rd_kafka_assign(self, list)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # List the current partition assignment(s) for the consumer.
    #
    # @raise [ResponseError] Error that occurred retrieving the assignments.
    #
    # @retunr [TopicPartitionList] List of current assignments
    def assignment
      ptr = ::FFI::MemoryPointer.new(:pointer)

      resp = ::Kafka::FFI.rd_kafka_assignment(self, ptr)
      if resp != :ok
        raise ResponseError, resp
      end

      ::Kafka::FFI::TopicPartitionList.new(ptr.read_pointer)
    ensure
      ptr.free
    end

    # Retrieve committed offsets for topics + partitions. The offset field for
    # each TopicPartition in list will be set to the stored offset or
    # RD_KAFKA_OFFSET_INVALID in case there was no stored offset for that
    # partition. The error field is set if there was an error with the
    # TopicPartition.
    #
    # @param list [TopicPartitionList] List of TopicPartitions to fetch offsets
    #   for.
    # @param timeout [Integer] Maximum time to wait in milliseconds
    #
    # @raise [ResponseError] Error with the request (likely a timeout). Errors
    #   with individual topic+partition combinations are set in the returned
    #   TopicPartitionList
    def committed(list, timeout: 1000)
      if list.nil?
        raise ArgumentError, "list cannot be nil"
      end

      err = ::Kafka::FFI.rd_kafka_committed(self, list, timeout)
      if err != :ok
        raise ResponseError, err
      end

      # Return the list that was passed in as it should now be augmented with
      # the committed offsets and any errors fetching said offsets.
      list
    end

    # Poll the consumer's queue for a waiting Message.
    #
    # @param timeout [Integer] How long to wait for a message in milliseconds.
    #
    # @return [Message, nil] The polled Message or nil if no messages were
    #   available within the timeout.
    def consumer_poll(timeout)
      msg = ::Kafka::FFI.rd_kafka_consumer_poll(self, timeout.to_i)

      msg.null? ? nil : msg
    end

    # Commit the set of offsets from the given TopicPartitionList.
    #
    # @param offsets [TopicPartitionList] Set of topic+partition with offset
    #   (and maybe metadata) to be committed. If offsets is nil the current
    #   partition assignment set will be used instead.
    # @param async [Boolean] If async is false this operation will block until
    #   the broker offset commit is done.
    #
    # @raise [ResponseError] Error committing offsets. Only raise if async is
    #   false.
    def commit(offsets, async)
      err = ::Kafka::FFI.rd_kafka_commit(self, offsets, async)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # Commit the message's offset on the broker for the message's partition.
    #
    # @param message [Message] The message to commit as processed
    # @param async [Boolean] True to allow commit to happen in the background.
    #
    # @raise [ResponseError] Error that occurred commiting the message
    def commit_message(message, async)
      if message.nil? || message.null?
        raise ArgumentError, "message cannot but nil/null"
      end

      err = ::Kafka::FFI.rd_kafka_commit_message(message, async)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # Close down the consumer. This will block until the consumer has revoked
    # its assignment(s), committed offsets, and left the consumer group. The
    # maximum blocking time is roughly limited to the `session.timeout.ms`
    # config option.
    #
    # Ensure that `destroy` is called after the consumer is closed to free up
    # resources.
    #
    # @return [Symbol, Integer] :ok on success otherwise an error code.
    def close
      ::Kafka::FFI.rd_kafka_consumer_close(self)
    end
  end
end
