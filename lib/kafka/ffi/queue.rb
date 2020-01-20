# frozen_string_literal: true

require "ffi"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Queue < OpaquePointer
    def self.new(client)
      ::Kafka::FFI.rd_kafka_queue_new(client)
    end

    # Poll a queue for an event, waiting up to timeout milliseconds. Takes an
    # optional block which will handle destroying the event at the completion
    # of the block.
    #
    # @param timeout [Integer] Max time to wait in millseconds for an Event.
    #
    # @yield [event]
    # @yieldparam event [Event] Polled event
    #
    # @return [nil] No event was available within the timeout
    # @return [Event] Event polled from the queue, application is responsible
    #   for calling #destroy on the Event when finished with it.
    # @return When passed a block, the result returned by the block
    def poll(timeout: 1000)
      event = ::Kafka::FFI.rd_kafka_queue_poll(self, timeout)
      if event.nil?
        return nil
      end

      if block_given?
        begin
          yield(event)
        ensure
          event.destroy
        end
      else
        event
      end
    end

    # Forward events meant for this Queue to the destination Queue instead.
    #
    # @param dest [Queue] Destination queue to forward
    # @param dest [nil] Remove forwarding for this queue.
    def forward(dest)
      ::Kafka::FFI.rd_kafka_queue_forward(self, dest)
    end

    # Retrieve the current number of elemens in the queue.
    #
    # @return [Integer] Number of elements in the queue
    def length
      ::Kafka::FFI.rd_kafka_queue_length(self)
    end

    # Release the applications reference on the queue, possibly destroying it
    # and releasing it's resources.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_queue_destroy(self)
      end
    end
  end
end
