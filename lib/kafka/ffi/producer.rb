# frozen_string_literal: true

require "ffi"
require "kafka/ffi/client"

module Kafka::FFI
  class Producer < Kafka::FFI::Client
    def self.new(config = nil)
      super(:producer, config)
    end

    # Produce and send a single message to the Kafka cluster.
    #
    # @param topic [Topic, String] Topic (or name of topic) to receive the
    #   message.
    #
    # @param payload [String, nil] Content of the message.
    #
    # @param key [String] Message partitioning key
    #
    # @param partition [nil, -1] Use the configured partitioner to determine
    #   which partition to publish the message to.
    # @param partition [Integer] Partition of the topic that should receive the
    #   message.
    #
    # @param headers [Kafka::FFI::Message::Header]
    #
    # @param timestamp [Time, Integer]
    # @param timestamp [nil] Timestamp is assigned by librdkafka
    #
    # @param opaque [Object] Ruby object that will be available (as an
    #   FFI::Pointer) in some callbacks. The caller MUST maintain a reference
    #   to the object until all callbacks are finished otherwise it will cause
    #   a segfault when the object is garbage collected.
    def produce(topic, payload, key: nil, partition: nil, headers: nil, timestamp: nil, opaque: nil)
      args = [
        # Ensure librdkafka copies the payload into its own memory since the
        # string backing it could be garbage collected.
        :vtype, :msgflags, :int, Kafka::FFI::RD_KAFKA_MSG_F_COPY,
      ]

      if payload
        args.append(:vtype, :value, :buffer_in, payload, :size_t, payload.bytesize)
      end

      # The partitioning key is optional
      if key
        args.append(:vtype, :key, :buffer_in, key, :size_t, key.bytesize)
      end

      # Partition will default to being auto assigned by the configured
      # partitioning strategy.
      if partition
        args.append(:vtype, :partition, :int32, partition)
      end

      # Headers are optional and can be passed as either a reference to a
      # Header object or individual key/value pairs. This only supports the
      # Header object because supporting key + valu
      if headers
        args.append(:vtype, :headers, :pointer, headers.pointer)
      end

      case topic
      when Topic
        args.append(:vtype, :rkt, :pointer, topic.pointer)
      when String
        args.append(:vtype, :topic, :string, topic)
      else
        raise ArgumentError, "topic must be either a Topic or String"
      end

      if opaque
        ptr = ::FFI::Pointer.new(:pointer, opaque.object_id << 1)
        args.append(:vtype, :opaque, :pointer, ptr)
      end

      if timestamp
        ts =
          case timestamp
          when Time    then ((timestamp.to_i * 1000) + (timestamp.nsec / 1000))
          when Integer then timestamp
          else
            raise ArgumentError, "timestamp must be nil, a Time, or an Integer"
          end

        args.append(:vtype, :timestamp, :int64, ts)
      end

      # Add the sentinel value to denote the end of the argument list.
      args.append(:vtype, :end)

      err = ::Kafka::FFI.rd_kafka_producev(self, *args)
      if err != :ok
        # The only documented error is RD_KAFKA_RESP_ERR__CONFLICT should both
        # HEADER and HEADERS keys be passed in. There is no way for HEADER to
        # be passed to producev based on the above implementation.
        raise ResponseError, err
      end

      nil
    end

    # Wait until all outstanding produce requests are completed. This should
    # typically be done prior to destroying a producer to ensure all queued and
    # in-flight requests are completed before terminating.
    #
    # @raise [ResponseError] Timeout was reached before all outstanding
    #   requests were completed.
    def flush(timeout: 1000)
      err = ::Kafka::FFI.rd_kafka_flush(self, timeout)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # Purge messages currently handled by the Producer. By default this will
    # purge all queued and inflight messages asyncronously.
    #
    # @param queued [Boolean] Purge any queued messages
    # @param inflight [Boolean] Purge messages that are inflight
    # @param blocking [Boolean] When true don't wait for background thread
    #   queue purging to finish.
    #
    # @raise [ResponseError] Error occurred purging state. This is unlikely as
    #   the documented error are not possible with this implementation.
    def purge(queued: true, inflight: true, blocking: false)
      mask = 0
      mask |= RD_KAFKA_PURGE_F_QUEUE if queued
      mask |= RD_KAFKA_PURGE_F_INFLIGHT if inflight
      mask |= RD_KAFKA_PURGE_F_NON_BLOCKING if blocking

      err = ::Kafka::FFI.rd_kafka_purge(self, mask)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end
  end
end
