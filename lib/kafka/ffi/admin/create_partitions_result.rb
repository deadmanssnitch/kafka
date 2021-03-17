# frozen_string_literal: true

require "kafka/ffi/admin/topic_result"

module Kafka::FFI::Admin
  class CreatePartitionsResult < ::Kafka::FFI::Event
    event_type :create_partitions

    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_CreatePartitions_result(event)
    end

    # Retrives the opaque object set on the AdminOptions for the request.
    #
    # @note It is the applications responsibility to call #free on the return
    #   Opaque if it is no longer needed after handling the event.
    #
    # @return [Kafka::FFI::Opaque, nil] Opaque set via AdminOptions or nil if
    #   not available.
    def opaque
      ::Kafka::FFI.rd_kafka_event_opaque(self)
    end

    # Retrieve details about the topics affected by the CreatePartitions
    # operation.
    #
    # @return [Array<TopicResult>] Details of affected topics
    def topics
      count = ::FFI::MemoryPointer.new(:size_t)

      topics = ::Kafka::FFI.rd_kafka_CreatePartitions_result_topics(self, count)
      topics = topics.read_array_of_pointer(count.read(:size_t))
      topics.map! { |r| TopicResult.new(r) }
    ensure
      count.free
    end
  end
end
