# frozen_string_literal: true

require "kafka/ffi/admin/topic_result"

module Kafka::FFI::Admin
  # DeleteGroupsResult is returned by the DeleteGroups admin command.
  #
  # @see #groups
  class DeleteGroupsResult < ::Kafka::FFI::Event
    event_type :delete_groups

    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_DeleteGroups_result(event)
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

    # Retrieve the set of deleted groups from the DeleteGroup operation.
    #
    # @return [Array<GroupResult>] Info about the groups that were deleted.
    def groups
      count = ::FFI::MemoryPointer.new(:size_t)

      groups = ::Kafka::FFI.rd_kafka_DeleteGroups_result_groups(self, count)
      groups = groups.read_array_of_pointer(count.read(:size_t))
      groups.map! { |r| GroupResult.new(r) }
    ensure
      count.free
    end
  end
end
