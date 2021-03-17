# frozen_string_literal: true

require "kafka/ffi/admin/topic_result"

module Kafka::FFI::Admin
  class DeleteTopicsResult < ::Kafka::FFI::Event
    event_type :delete_topics

    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_DeleteTopics_result(event)
    end

    # Retrieve details about the topics affected by the DeleteTopics operation.
    #
    # @return [Array<TopicResult>] Details of affected topics
    def topics
      count = ::FFI::MemoryPointer.new(:size_t)

      topics = ::Kafka::FFI.rd_kafka_DeleteTopics_result_topics(self, count)
      topics = topics.read_array_of_pointer(count.read(:size_t))
      topics.map! { |r| TopicResult.new(r) }
    ensure
      count.free
    end
  end
end
