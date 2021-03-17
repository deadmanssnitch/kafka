# frozen_string_literal: true

module Kafka::FFI
  class OffsetCommitEvent < Event
    event_type :offset_commit

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
