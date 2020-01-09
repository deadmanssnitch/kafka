# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Topic < OpaquePointer
    # Retrieve the name of the topic
    #
    # @return [String] Name of the topic
    def name
      ::Kafka::FFI.rd_kafka_topic_name(self)
    end

    # Seek consumer for topic_partition to offset.
    #
    # @param partition [Integer] Partition to set offset for
    # @param offset [Integer] Absolute or logical offset
    # @param timeout [Integer] Maximum time to wait in milliseconds
    #
    # @return [Boolean] True when the consumer's offset was changed
    def seek(partition, offset, timeout: 1000)
      ::Kafka::FFI.rd_kafka_seek(self, partition, offset, timeout)
    end

    # Release the application's hold on the backing topic in librdkafka.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_topic_destroy(self)
      end
    end
  end
end
