# frozen_string_literal: true

require "kafka/poller"

module Kafka
  class Producer
    require "kafka/producer/delivery_report"

    # Returns the backing Kafka::FFI::Producer.
    #
    # @DANGER Using the backing Producer means being aware of memory management
    #   and could leave the producer in a bad state. Make sure you know what
    #   you're doing.
    #
    # @return [Kafka::FFI::Producer]
    attr_reader :client

    # Initialize a new Producer for the configured cluster.
    #
    # @param config [Config]
    def initialize(config)
      config = config.dup

      # Configure callbacks
      config.on_delivery_report(&method(:on_delivery_report))

      @client = ::Kafka::FFI::Producer.new(config)

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
    # @param block [Proc] Optional asyncronous callback to be called when the
    #   delivery status of the message is reported back from librdkafka. The
    #   callback MUST avoid expensive or long running processing as that may
    #   causes issues inside librdkafka.
    #
    # @yield [report] Called asyncronously when the report is received from
    #   Kafka on the success or failure of the delivery.
    # @yieldparam report [DeliveryReport] Delivery status of the message.
    #
    # @return [DeliveryReport] Report of the success or failure of the
    #   delivery. Call #wait to block until the report is received.
    def produce(topic, payload, key: nil, partition: nil, headers: nil, timestamp: nil, &block)
      report = DeliveryReport.new(&block)

      # Allocate a pointer to a small chunk of memory. We will use the pointer
      # (not the value it points to) as a key for looking up the DeliveryReport
      # in the callback.
      #
      # Using a MemoryPointer as a key also ensures we have a reference to the
      # Pointer so it doesn't get garbage collected away and it can be freed it
      # in the callback since the raw FFI::Pointer disallows #free as FFI
      # doesn't believe we allocated it.
      opaque = Kafka::FFI::Opaque.new(report)

      @client.produce(topic, payload, key: key, partition: partition, headers: headers, timestamp: timestamp, opaque: opaque)

      report
    rescue
      opaque.free

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
      op = message.opaque
      if op.nil?
        return
      end

      begin
        report = op.value
        report.done(message)
      ensure
        op.free
      end
    end
  end
end
