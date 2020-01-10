# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Event < OpaquePointer
    # LogMessage is attached to RD_KAFKA_EVENT_LOG events.
    LogMessage = Struct.new(:facility, :message, :level) do
      # @attr facility [String] Log facility
      # @attr message [String] Log message
      # @attr level [Integer] Verbosity level of the message

      def to_s
        message
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

    # Retrieve the set of messages. Can take a block to iterate over the set of
    # Messages rather than return them.
    #
    # Events:
    #   - RD_KAFKA_EVENT_FETCH
    #   - RD_KAFKA_EVENT_DR
    #
    # @note Do not call #destroy on the Messages
    #
    # @yield [message] Iterate over available messages
    # @yieldparam [Message]
    #
    # @return [Array<Message>] Messages attached to the Event
    # @return [nil] Event does not have any Messages or a block was given.
    def messages
      # This departs from the librdkafka API due to having a collection of
      # methods that have funky semantics for Ruby.

      # @todo Messages are only on RD_KAFKA_EVENT_FETCH and RD_KAFKA_EVENT_DR.
      #   Need to test what happens with other event types.

      # No block so fetch all of the messages and return them as an array.
      if !block_given?
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
          return ptr.read_array_of_pointer(ret).map! { |p| Message.from_native(p) }
        ensure
          ptr.free
        end
      end

      # Block was passed so use rd_kafka_event_message_next
      begin
        ptr = ::FFI::MemoryPointer.new(:pointer)

        loop do
          msg = ::Kafka::FFI.rd_kafka_event_message_next(self)
          if msg.null?
            break
          end

          yield(msg)
        end
      ensure
        ptr.free
      end
    end

    # Returns the configuration for the event or nil if the configuration
    # property is not set or not applicable for the event type.
    #
    # Events:
    #   - RD_KAFKA_EVENT_OAUTHBEARER_TOKEN_REFRESH
    #
    # @return [String] Configuration string for the event
    # @return [nil] Property not set or not applicable.
    def config_string
      ::Kafka::FFI.rd_kafka_event_string(self)
    end

    # Returns the error code for the event or nil if there was no error.
    #
    # @see error_is_fatal to detect if it is a fatal error.
    #
    # @return [nil] No error for the Event
    # @return [RD_KAFKA_RESP_ERR_*] Error code for the event.
    def error
      # @todo Would prefer this to return a Error type with fatal? and to_s.
      #   Could it just be a ResponseError?
      err = ::Kafka::FFI.rd_kafka_event_error(self)
      err == :ok ? nil : err
    end

    # Returns a description of the error or nil when there is no error.
    #
    # @return [nil] No error for the Event
    # @return [String] Description of the error
    def error_string
      if error
        ::Kafka::FFI.rd_kafka_event_error_string(self)
      end
    end

    # Returns true or false if the Event represents a fatal error.
    #
    # @return [Boolean] There is an error for the Event and it is fatal.
    def error_is_fatal
      error && ::Kafka::FFI.rd_kafka_event_error_is_fatal(self)
    end
    alias error_is_fatal? error_is_fatal

    # Returns the log message attached to the event.
    #
    # Events:
    #   - RD_KAFKA_EVENT_LOG
    #
    # @return [Event::LogMessage] Attach log entry
    def log
      facility = ::FFI::MemoryPointer.new(:pointer)
      message  = ::FFI::MemoryPointer.new(:pointer)
      level    = ::FFI::MemoryPointer.new(:pointer)

      exists = ::Kafka::FFI.rd_kafka_event_log(self, facility, message, level)
      if exists != 0
        # Event type does not support log messages.
        return nil
      end

      LogMessage.new(facility.read_string, message.read_string, level.read_int)
    ensure
      facility.free
      message.free
      level.free
    end

    # Extracts stats from the event
    #
    # Events:
    #   - RD_KAFKA_EVENT_STATS
    #
    # @return [nil] Event type does not support stats
    # @return [String] JSON encoded stats information.
    def stats
      # Calling stats on an unsupported type causes a segfault with librdkafka
      # 1.3.0.
      if type != :stats
        return nil
      end

      ::Kafka::FFI.rd_kafka_event_stats(self)
    end

    # Returns the topic partition list from the Event.
    #
    # @note Application MUST NOT call #destroy on the list
    #
    # Events:
    #   - RD_KAFKA_EVENT_REBALANCE
    #   - RD_KAFKA_EVENT_OFFSET_COMMIT
    #
    # @return [TopicPartitionList]
    def topic_partition_list
      ::Kafka::FFI.rd_kafka_event_topic_partition_list(self)
    end

    # Returns the topic partition from the Event.
    #
    # @note The application MUST call #destroy on the TopicPartition when done.
    #
    # Events:
    #   - RD_KAFKA_EVENT_ERROR
    #
    # @return [TopicPartition]
    def topic_partition
      ::Kafka::FFI.rd_kafka_event_topic_partition(self)
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
