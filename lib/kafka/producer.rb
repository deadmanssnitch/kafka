# frozen_string_literal: true

require "kafka/poller"

module Kafka
  class Producer
    require "kafka/producer/delivery_report"

    # Initialize a new Producer for the configured cluster.
    #
    # @param config [Config]
    def initialize(config)
      config = config.native

      # Configure callbacks
      config.set_dr_msg_cb(&method(:on_delivery_report))
      config.set_error_cb(&method(:on_error))

      @client = ::Kafka::FFI::Producer.new(config)

      # Maintains a list of in-flight deliveries that we're waiting for reports
      # for. If we don't, it is possible that Ruby will garbage collect them
      # before on_delivery_report is called causing memory corruption or
      # segfaults.
      @in_flight = {}

      # Periodically call poll on the client to ensure callbacks are fired.
      @poller = Poller.new(@client)
    end

    # Produce and publish a message to the Kafka cluster.
    #
    # @param topic [String] Topic to publish the message to
    # @param payload [String] Message's payload
    # @param key [String] Optional partitioning key Kafka can use to determine
    #   the correct partition.
    # @param partition [-1, nil] Kafka will determine the partition
    #   automatically based on the `partitioner` config option.
    # @param partition [Integer] Specifiy partition to publish the message to.
    # @param headers [Hash{String => String}] Set of headers to attach to the
    #   message.
    # @param timestamp [nil] Let Kafka automatically assign Message timestamp
    # @param timestamp [Time] Timestamp for the message
    # @param timestamp [Integer] Timestamp as milliseconds since unix epoch
    #
    # @yield [report]
    # @yieldparam report [DeliveryReport] Get the delivery status of the message.
    #
    # @return [DeliveryReport] When no block is given, returns the
    #   DeliveryReport to get status of delivery.
    # @return When a block is given, returns the result of the block.
    def produce(topic, payload, key: nil, partition: nil, headers: nil, timestamp: nil)
      report = DeliveryReport.new

      # Allocate a pointer to a small chunk of memory. We will use the pointer
      # (not the value it points to) as a key for looking up the DeliveryReport
      # in the callback.
      #
      # Using a MemoryPointer as a key also ensures we have a reference to the
      # Pointer so it doesn't get garbage collected away and it can be freed it
      # in the callback since the raw FFI::Pointer disallows #free as FFI
      # doesn't believe we allocated it.
      opaque = ::FFI::MemoryPointer.new(:int8)

      # Add the report to in-flight messages. This needs to happen before
      # calling `produce` to avoid threading issues where the callback is
      # triggered before the insert to the hash is complete.
      @in_flight[opaque] = report

      @client.produce(topic, payload, key: key, partition: partition, headers: headers, timestamp: timestamp, opaque: opaque)

      if block_given?
        yield(report)
      else
        report
      end
    rescue
      # Failed publishing the message to Kafka so there won't be a callback.
      @in_flight.delete(opaque)

      raise
    end

    # Wait until all outstanding produce requests are completed.
    #
    # @raise [Kafka::ResponseError] Timeout was reached before all
    #   outstanding requests were completed.
    def flush(timeout: 1000)
      @client.flush(timeout: timeout)
    end

    # Gracefully shutdown the Producer, flushing any pending deliveries, and
    # finally releasing an memory back to the system.
    #
    # @note Once #close is call it is no longer safe to call any other method
    #   on the Producer.
    #
    # @param timeout [Integer] Maximum time to wait in milliseconds for
    #   messages to be flushed.
    def close(timeout: 30000)
      # @see https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md#producer
      @poller.stop

      @client.flush(timeout: timeout)
      @client.poll

      # Client handles destroying cached Topics
      @client.destroy
    end

    private

    # @param client [Kafka::FFI::Producer]
    # @param message [Kafka::FFI::Message]
    # @param opaque [FFI::Pointer]
    def on_delivery_report(_client, message, _opaque)
      # The message.opaque pointer is a raw FFI::Pointer with the same address
      # as the key used to track the DeliveryReport. Find the equivalent key
      # and it's value.
      key, report = @in_flight.assoc(message.opaque)
      if key.nil?
        return
      end

      report.done(message)
    ensure
      if key
        @in_flight.delete(key)
        key.free
      end
    end

    # @param client [Kafka::FFI::Producer]
    # @param error [Integer]
    # @param reason [String]
    # @param opaque [FFI::Pointer]
    def on_error(_client, error, reason, _opaque)
      # @todo Bubble up to app.
    end
  end
end
