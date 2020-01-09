# frozen_string_literal: true

require "ffi"
require "kafka/ffi/topic_partition"

module Kafka::FFI
  class TopicPartitionList < ::FFI::Struct
    layout(
      :cnt,   :int,
      :size,  :int,
      :elems, :pointer
    )

    # New initializes a new TopicPartitionList with an initial capacity to hold
    # `count` items.
    #
    # @param count [Integer] Initial capacity
    #
    # @return [TopicPartitionList] An empty TopicPartitionList
    def self.new(count = 0)
      # Handle initialization through FFI. This will be called by
      # rd_kafka_topic_partition_list_new.
      if count.is_a?(::FFI::Pointer)
        return super(count)
      end

      ::Kafka::FFI.rd_kafka_topic_partition_list_new(count)
    end

    # Returns the number of elements in the TopicPartitionList.
    #
    # @return [Integer] Number of elements
    def size
      self[:cnt]
    end

    # Returns true when the TopicPartitionList is empty
    #
    # @return [Boolean] True when the list is empty
    def empty?
      size == 0
    end

    # Add a topic + partition combination to the list
    #
    # @param topic [String] Name of the topic to add
    # @param partition [Integer] Partition of the topic to add to the list. Use
    #   -1 to subscribe to all partitions for the topic.
    #
    # @return [TopicPartition] TopicPartition for the combination
    def add(topic, partition = -1)
      ::Kafka::FFI.rd_kafka_topic_partition_list_add(self, topic.to_s, partition)
    end

    # Add a range of TopicPartitions to the list.
    #
    # @param topic [String] Name of the topic to add
    # @param range_or_lower [Range, Integer] Either a Range specifying the
    #   Range of partitions or the lower bound for the range. When providing a
    #   Range any value for upper is ignored.
    # @param upper [Integer, nil] The upper bound of the set of partitions
    #   (inclusive). Required unless range_or_lower is a Range.
    def add_range(topic, range_or_lower, upper = nil)
      lower = range_or_lower

      # Allows passing a Range for convenience.
      if range_or_lower.is_a?(Range)
        lower = range_or_lower.min
        upper = range_or_lower.max
      elsif upper.nil?
        raise ArgumentError, "upper was nil but must be provided when lower is not a Range"
      end

      ::Kafka::FFI.rd_kafka_topic_partition_list_add_range(self, topic.to_s, lower.to_i, upper.to_i)
    end

    # Remove a TopicPartition by partition
    #
    # @param topic [String] Name of the topic to remove
    # @param partition [Integer] Partition to remove
    #
    # @return [Boolean] True when the partition was found and removed
    def del(topic, partition)
      ::Kafka::FFI.rd_kafka_topic_partition_list_del(self, topic.to_s, partition) == 1
    end

    # Remove a TopicPartition by index
    #
    # @param idx [Integer] Index in elements to remove
    #
    # @return [Boolean] True when the TopicPartition was found and removed
    def del_by_idx(idx)
      ::Kafka::FFI.rd_kafka_topic_partition_list_del_by_idx(self, idx) == 1
    end

    alias delete del
    alias delete_by_index del_by_idx

    # Duplicate the TopicPartitionList as a new TopicPartitionList that is
    # identical to the current one.
    #
    # @return [TopicPartitionList] New clone of this TopicPartitionList
    def copy
      ::Kafka::FFI.rd_kafka_topic_partition_list_copy(self)
    end

    # Set the consumed offset for topic and partition
    #
    # @param topic [String] Name of the topic to set the offset for
    # @param partition [Integer] Partition to set the offset for
    # @param offset [Integer] Offset of the topic+partition to set
    #
    # @return [Integer] 0 for success otherwise rd_kafka_resp_err_t code
    def set_offset(topic, partition, offset)
      ::Kafka::FFI.rd_kafka_topic_partition_list_set_offset(self, topic, partition, offset)
    end

    # Sort the TopicPartitionList. Sort can take a block that should implement
    # a standard comparison function that returns -1, 0, or 1 depending on if
    # left is less than, equal to, or greater than the right argument.
    #
    # @example Custom sorting function
    #   sort do |left, right|
    #     left.partition <=> right.partition
    #   end
    def sort(&block)
      ::Kafka::FFI.rd_kafka_topic_partition_list_sort(self, block, nil)
    end

    # Find the TopicPartition in the set for the given topic + partition. Will
    # return nil if the list does not include the combination.
    #
    # @param topic [String] Name of the topic
    # @param partition [Integer] Topic partition
    #
    # @return [TopicPartition, nil] The TopicPartion for the topic + partition
    #   combination.
    def find(topic, partition)
      result = ::Kafka::FFI.rd_kafka_topic_partition_list_find(self, topic, partition)

      if result.null?
        return nil
      end

      result
    end

    # Retrieves the set of TopicPartitions for the list.
    #
    # @return [Array<TopicPartition>]
    def elements
      self[:cnt].times.map do |i|
        TopicPartition.new(self[:elems] + (i * TopicPartition.size))
      end
    end

    # Free all resources used by the list and the list itself. Usage it
    # dependent on the semantics of librdkafka, so make sure to only call on
    # TopicPartitionLists that are not owned by objects. Generally, if you
    # constructed the object it should be safe to destroy.
    def destroy
      if !null?
        ::Kafka::FFI.rd_kafka_topic_partition_list_destroy(self)
      end
    end
  end
end
