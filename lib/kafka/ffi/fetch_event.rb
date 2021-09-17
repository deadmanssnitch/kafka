# frozen_string_literal: true

module Kafka::FFI
  class FetchEvent < Event
    event_type :fetch

    # Retrieve the set of messages attached to the event.
    #
    # @note Do not call #destroy on the Messages
    #
    # @return [Array<Message>] Messages attached to the Event
    def messages
      count = ::Kafka::FFI.rd_kafka_event_message_count(self)
      if count == 0
        return []
      end

      begin
        # Allocates enough memory for the full set but only converts as many
        # as were returned.
        # @todo Retrieve all until sum(ret) == count?
        ptr = ::FFI::MemoryPointer.new(:pointer, count)
        ret = ::Kafka::FFI.rd_kafka_event_message_array(self, ptr, count)

        # Map the return pointers to Messages
        return ptr.read_array_of_pointer(ret).map! { |p| Message.new(p) }
      ensure
        ptr.free
      end
    end
  end
end
