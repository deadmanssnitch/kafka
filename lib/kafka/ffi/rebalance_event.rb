# frozen_string_literal: true

module Kafka::FFI
  class RebalanceEvent < Event
    event_type :rebalance

    # Returns the list of topic partition pairs now assigned to the consumer
    # during the rebalance.
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
