# frozen_string_literal: true

module Kafka::FFI
  class LogEvent < Event
    event_type :log

    Message = Struct.new(:facility, :message, :level) do
      # @attr facility [String] Log facility
      # @attr message [String] Log message
      # @attr level [Integer] Verbosity level of the message

      def to_s
        message
      end
    end

    # Returns the log message attached to the event.
    #
    # @return [LogEvent::Message] Attached log entry
    def log
      facility = ::FFI::MemoryPointer.new(:pointer)
      message  = ::FFI::MemoryPointer.new(:pointer)
      level    = ::FFI::MemoryPointer.new(:pointer)

      exists = ::Kafka::FFI.rd_kafka_event_log(self, facility, message, level)
      if exists != 0
        # Event type does not support log messages.
        return nil
      end

      Message.new(
        facility.read_pointer.read_string,
        message.read_pointer.read_string,
        level.read_int,
      )
    ensure
      facility.free
      message.free
      level.free
    end

    # Extract log debug context from the event
    #
    # @return [String, nil] Log debug context or nil if not supported.
    def debug_contexts
      ctx = ::FFI::MemoryPointer.new(:char, 1024)
      err = ::Kafka::FFI.rd_kafka_event_debug_contexts(self, ctx, ctx.size)

      # -1 is returned if event doesn't support debug_contexts
      if err != 0
        return nil
      end

      ctx.read_string
    ensure
      ctx.free
    end
  end
end
