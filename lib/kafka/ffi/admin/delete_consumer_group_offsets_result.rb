# frozen_string_literal: true

module Kafka::FFI::Admin
  class DeleteConsumerGroupOffsetsResult < ::Kafka::FFI::Event
    event_type :delete_consumer_group_offets

    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_DeleteConsumerGroupOffsets_result(event)
    end

    # Retrieve details about the groups affected by the
    # DeleteConsumerGroupOffsets operation. The offset will be the previous
    # committed offset as of deletion.
    #
    # @return [Array<GroupResult>] Details about the groups affected.
    def groups
      count = ::FFI::MemoryPointer.new(:size_t)

      groups = ::Kafka::FFI.rd_kafka_DeleteConsumerGroupOffsets_result_groups(self, count)
      groups = groups.read_array_of_pointer(count.read(:size_t))
      groups.map! { |r| GroupResult.new(r) }
    ensure
      count.free
    end
  end
end
