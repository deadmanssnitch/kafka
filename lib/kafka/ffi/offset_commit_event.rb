# frozen_string_literal: true

module Kafka::FFI
  class OffsetCommitEvent < Event
    event_type :offset_commit

    # Retrives the opaque object provided when committing the offsets.
    #
    # @note It is the applications responsibility to call #free on the return
    #   Opaque if it is no longer needed after handling the event.
    #
    # @return [Kafka::FFI::Opaque, nil] Opaque set when committing offsets or
    #   nil when not provided.
    def opaque
      ::Kafka::FFI.rd_kafka_event_opaque(self)
    end

    # Returns the list of offsets that were committed.
    #
    # @note Application MUST NOT call #destroy on the list
    #
    # @return [TopicPartitionList, nil]
    def topic_partition_list
      tpl = ::Kafka::FFI.rd_kafka_event_topic_partition_list(self)
      tpl.null? ? nil : tpl
    end
  end
end
