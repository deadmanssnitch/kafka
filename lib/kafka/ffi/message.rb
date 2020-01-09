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
      :_private,  :pointer # DO NOT TOUCH. Internal to librdkafka
    )

    def topic
      if self[:rkt].nil?
        return nil
      end

      ::Kafka::FFI.rd_kafka_topic_name(self[:rkt])
    end

    def key
      if self[:key].null?
        return nil
      end

      self[:key].read_string(self[:key_len])
    end

    def partition
      self[:partition]
    end

    def offset
      self[:offset]
    end

    def payload
      if self[:payload].null?
        return nil
      end

      self[:payload].read_string(self[:len])
    end

    # Get the message header list
    #
    # @raise [ResponseError] Error occurred parsing headers
    #
    # @return [nil] Message does not have any headers
    # @return [Message::Headers] Set of headers
    def headers
      ptr = ::FFI::MemoryPointer.new(:pointer)

      err = ::Kafka::FFI.rd_kafka_message_headers(self, ptr)
      case err
      when :ok
        if ptr.null?
          nil
        else
          Message::Headers.new(ptr)
        end
      when RD_KAFKA_RESP_ERR__NOENT
        # Messages does not have headers
        nil
      else
        raise ResponseError, err
      end
    ensure
      ptr.free
    end

    # Get the Message's headers and detach them from the Message (setting its
    # headers to nil). Calling detach_headers means the applicaiton is now the
    # owner of the returned Message::Header and must eventually call #destroy
    # when the application is done with them.
    #
    # @raise [ResponseError] Error occurred parsing headers
    #
    # @return [nil] Message does not have any headers
    # @return [Message::Headers] Set of headers
    def detach_headers
      ptr = ::FFI::MemoryPointer.new(:pointer)

      err = ::Kafka::FFI.rd_kafka_message_detach_headers(self, ptr)
      case err
      when :ok
        if ptr.null?
          nil
        else
          Message::Headers.new(ptr)
        end
      when RD_KAFKA_RESP_ERR__NOENT
        # Messages does not have headers
        nil
      else
        raise ResponseError, err
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
    # @return [Time] Message timestamp
    # @return [nil] Timestamp is not available
    def timestamp
      # @todo: Return Integer? Optimization for storage in downstream object since creating a Time is expensive
      # @todo: Type (second param) [rd_kafka_timestamp_type_t enum]
      ts = ::Kafka::FFI.rd_kafka_message_timestamp(self, nil)

      if ts == -1
        return nil
      end

      Time.at(Rational(ts) / 1000.0).utc
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
