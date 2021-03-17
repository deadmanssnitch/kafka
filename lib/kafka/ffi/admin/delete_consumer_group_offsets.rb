# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  # DeleteConsumerGroupOffsets is an admin operation to delete committed
  # offsets for a consumer group.
  class DeleteConsumerGroupOffsets < ::Kafka::FFI::OpaquePointer
    # Initialize a new DeleteConsumerGroupOffsets request to be passed to the
    # Admin API.
    #
    # @note The application is responsible for calling #destroy to free memory.
    #
    # @param group [String] Consumer group id
    # @param partitions [TopicPartitionList] List of topic + partitions to
    #   delete committed offsets for the consumer group. Only the topic and
    #   partitions fields are used.
    def self.new(group, partitions)
      ::Kafka::FFI.rd_kafka_DeleteConsumerGroupOffsets_new(group, partitions)
    end

    # Release the resources used by the DeleteConsumerGroupOffsets. It is the
    # application's responsibility to call #destroy when it is done with the
    # object.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_DeleteConsumerGroupOffsets_destroy(self)
      end
    end
  end
end
