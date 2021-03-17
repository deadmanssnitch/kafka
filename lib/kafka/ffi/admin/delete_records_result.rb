# frozen_string_literal: true

module Kafka::FFI::Admin
  class DeleteRecordsResult < ::Kafka::FFI::Event
    event_type :delete_records

    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_DeleteRecords_result(event)
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

    # Get a list of topic and partitions results from the DeleteRecords
    # operation. The TopicPartitions in the returned list will have topic,
    # partition, offset, and err set. The offset will be set to the
    # post-deletion low-watermark (smallest available offset of all live
    # replicas). err will be set per-partition if deletion failed.
    #
    # @return [TopicPartitionList, nil] Post deletion state information about
    #   the set of topic and partitions that were affected by the delete.
    def offsets
      tpl = ::Kafka::FFI.rd_kafka_DeleteRecords_result_offsets(self)
      tpl.null? ? nil : tpl
    end
  end
end
