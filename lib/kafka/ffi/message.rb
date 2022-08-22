# frozen_string_literal: true

module Kafka::FFI
  class Message < ::FFI::Struct
    require "kafka/ffi/message/header"

    layout(
      :err,       :error_code,
      :rkt,       Topic,
      :partition, :int32,
      :payload,   :pointer,
      :len,       :size_t,
      :key,       :pointer,
      :key_len,   :size_t,
      :offset,    :int64,
      :private,   Opaque
    )

    # Retrieve the error associated with this message. For consumers this is
    # used to report per-topic+partition consumer errors. For producers this is
    # set when received in the dr_msg_cb callback to signify a fatal error
    # publishing the message.
    #
    # @return [nil] Message does not have an error
    # @return [Kafka::ResponseError] RD_KAFKA_RESP_ERR__* error code
    def error
      if self[:err] != :ok
        ::Kafka::ResponseError.new(self[:err])
      end
    end

    # Returns the name of the Topic the Message was published to.
    #
    # @return [nil] Topic information was not available
    # @return [String] Name of the Topic the message was published to.
    def topic
      if self[:rkt].nil?
        return nil
      end

      self[:rkt].name
    end

    # Returns the optional message key used to publish the message. This key is
    # used for partition assignment based on the `partitioner` or
    # `partitioner_cb` config options.
    #
    # @return [nil] No partitioning key was provided
    # @return [String] The partitioning key
    def key
      if self[:key].null?
        return nil
      end

      self[:key].read_string(self[:key_len])
    end

    # Returns the partition the message was published to.
    #
    # @return [Integer] Partition
    def partition
      self[:partition]
    end

    # Returns the message's offset as published in the topic's partition. When
    # error != nil, offset the error occurred at.
    #
    # @return [Integer] Message offset
    # @return [RD_KAFKA_OFFSET_INVALID] Message was retried and idempotence is
    #   enabled.
    def offset
      self[:offset]
    end

    # Returns the ID of the Broker that the message was produced to or fetched
    # from.
    #
    # @return [Integer, -1] ID of the broker the message was produced to or
    #   fetched from. Will be -1 when broker id is unknown.
    def broker_id
      ::Kafka::FFI.rd_kafka_message_broker_id(self)
    end

    # Returns the per message opaque pointer that was given to produce. This is
    # a pointer to a Ruby object owned by the application.
    #
    # @note Using the opaque is dangerous and requires that the application
    #   maintain a reference to the object passed to produce. Failing to do so
    #   will cause segfaults due to the object having been garbage collected.
    #
    # @example Retrieve object from opaque
    #   require "fiddle"
    #   obj = Fiddle::Pointer.new(msg.opaque.to_i).to_value
    #
    # @return [nil] Opaque was not set
    # @return [FFI::Pointer] Pointer to opaque address
    def opaque
      self[:private]
    end

    # Returns the message's payload. When error != nil, will contain a string
    # describing the error.
    #
    # @return [String] Message payload or error string.
    def payload
      if self[:payload].null?
        return nil
      end

      self[:payload].read_string(self[:len])
    end

    # Get the message header list
    #
    # @raise [Kafka::ResponseError] Error occurred parsing headers
    #
    # @return [nil] Message does not have any headers
    # @return [Message::Header] Set of headers
    def headers
      ptr = ::FFI::MemoryPointer.new(:pointer)

      err = ::Kafka::FFI.rd_kafka_message_headers(self, ptr)
      case err
      when :ok
        addr = ptr.read_pointer
        if addr.null?
          nil
        else
          Message::Header.new(addr)
        end
      when RD_KAFKA_RESP_ERR__NOENT
        # Messages does not have headers
        nil
      else
        raise ::Kafka::ResponseError, err
      end
    ensure
      ptr.free
    end

    # Get the Message's headers and detach them from the Message (setting its
    # headers to nil). Calling detach_headers means the applicaiton is now the
    # owner of the returned Message::Header and must eventually call #destroy
    # when the application is done with them.
    #
    # @raise [Kafka::ResponseError] Error occurred parsing headers
    #
    # @return [nil] Message does not have any headers
    # @return [Message::Header] Set of headers
    def detach_headers
      ptr = ::FFI::MemoryPointer.new(:pointer)

      err = ::Kafka::FFI.rd_kafka_message_detach_headers(self, ptr)
      case err
      when :ok
        if ptr.null?
          nil
        else
          Message::Header.new(ptr)
        end
      when RD_KAFKA_RESP_ERR__NOENT
        # Messages does not have headers
        nil
      else
        raise ::Kafka::ResponseError, err
      end
    ensure
      ptr.free
    end

    # rubocop:disable Naming/AccessorMethodName

    # Replace the Message's headers with a new set.
    #
    # @note The Message takes ownership of the headers and they will be
    #   destroyed automatically with the Message.
    def set_headers(headers)
      ::Kafka::FFI.rd_kafka_set_headers(self, headers)
    end
    alias headers= set_headers
    # rubocop:enable Naming/AccessorMethodName

    # Retrieve the timestamp for a consumed message.
    #
    # @example Convert timestamp to a Time
    #   ts = message.timestamp
    #   ts = ts && Time.at(0, ts, :millisecond).utc
    #
    # @return [Integer] Message timestamp as milliseconds since unix epoch
    # @return [nil] Timestamp is not available
    def timestamp
      # @todo: Type (second param) [rd_kafka_timestamp_type_t enum]
      ts = ::Kafka::FFI.rd_kafka_message_timestamp(self, nil)
      ts == -1 ? nil : ts
    end

    # Retrieve the latency since the Message was published to Kafka.
    #
    # @return [Integer] Latency since produce() call in microseconds
    # @return [nil] Latency not available
    def latency
      latency = ::Kafka::FFI.rd_kafka_message_latency(self)
      latency == -1 ? nil : latency
    end

    # Frees resources used by the messages and hands ownership by to
    # librdkafka. The application should call destroy when done processing the
    # message.
    def destroy
      if !null?
        ::Kafka::FFI.rd_kafka_message_destroy(self)
      end
    end
  end
end
