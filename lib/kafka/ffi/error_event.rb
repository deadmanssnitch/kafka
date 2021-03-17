# frozen_string_literal: true

module Kafka::FFI
  class ErrorEvent < Event
    event_type :error

    # Returns the topic partition from the Event.
    #
    # @note The application MUST call #destroy on the TopicPartition when done.
    #
    # @return [TopicPartition]
    def topic_partition
      ::Kafka::FFI.rd_kafka_event_topic_partition(self)
    end

    # Returns true or false if the Event represents a fatal error.
    #
    # @return [Boolean] There is an error for the Event and it is fatal.
    def is_fatal
      error? && ::Kafka::FFI.rd_kafka_event_error_is_fatal(self)
    end
    alias fatal? is_fatal
  end
end
