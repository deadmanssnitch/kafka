# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Event < OpaquePointer
    class << self
      # registry holds mappings of librdkafka Event constants (RD_KAFKA_EVENT_*)
      # to the class for that event. Classes are registered by calling the class
      # method event_type.
      def registry
        @registry ||= {}
      end

      # Registers the current event subclass to map to the given enum value.
      #
      # @see ffi.rb: enum :event_type
      #
      # @param type [Symbol] event type enum value
      def event_type(type)
        if Event.registry.key?(type)
          raise ArgumentError, "#{type} already mapped to #{Event.registry[type]}"
        end

        Event.registry[type] = self
      end

      def from_native(ptr, _ctx)
        if !ptr.is_a?(::FFI::Pointer)
          raise TypeError, "from_native can only convert from a ::FFI::Pointer to #{self}"
        end

        # The equivalent of a native NULL pointer is nil.
        if ptr.null?
          return nil
        end

        type  = ::Kafka::FFI.rd_kafka_event_type(ptr)
        klass = Event.registry[type] || Event

        obj = klass.allocate
        obj.send(:initialize, ptr)
        obj
      end

      # @param value [Opaque, nil]
      #
      # @return [FFI::Pointer] Pointer referencing the Event
      def to_native(value, _ctx)
        if value.nil?
          return ::FFI::Pointer::NULL
        end

        # Allow a ::FFI::Pointer to be passed through
        if value.is_a?(::FFI::Pointer)
          return value
        end

        if !value.is_a?(self)
          raise TypeError, "expected a kind of #{self}, was #{value.class}"
        end

        value.pointer
      end
    end

    # Returns the event's type
    #
    # @see RD_KAFKA_EVENT_*
    #
    # @return [Symbol] Type of the event
    def type
      ::Kafka::FFI.rd_kafka_event_type(self)
    end

    # Returns the name of the event's type.
    #
    # @return [String] Name of the type of event
    def name
      ::Kafka::FFI.rd_kafka_event_name(self)
    end

    # Returns the error code for the event or nil if there was no error.
    #
    # @see error_is_fatal to detect if it is a fatal error.
    #
    # @return [nil] No error for the Event
    # @return [Kafka::ResponseError] Error code for the event.
    def error
      err = ::Kafka::FFI.rd_kafka_event_error(self)
      if err != :ok
        ::Kafka::ResponseError.new(err, error_string)
      end
    end

    # Returns true when an error occurred at the event level. This only checks
    # if there was an error attached to the event, some events have more
    # granular errors embeded in their results. For example the
    # Kafka::FFI::Admin::DeleteTopicsResult event has potential errors on each
    # of the results included in #topics.
    #
    # @see #error
    # @see #successful?
    #
    # @return [Boolean] event level error occurred
    def error?
      ::Kafka::FFI.rd_kafka_event_error(self) != :ok
    end

    # Returns true when the event does not have an attached error.
    #
    # @see #error?
    #
    # @return [Boolean] Event does not have an error
    def successful?
      !error?
    end

    # Returns a description of the error or nil when there is no error.
    #
    # @return [String, nil] Description of the error or nil if the event did
    #   not have an error.
    def error_string
      ::Kafka::FFI.rd_kafka_event_error_string(self)
    end

    # Destroy the event, releasing it's resources back to the system.
    #
    # @todo Is the applicaiton responsible for calling #destroy?
    def destroy
      # It is safe to call destroy even if the Event's pointer is NULL but it
      # doesn't do anything so might as well guard against it just in case.
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_event_destroy(self)
      end
    end
  end
end
