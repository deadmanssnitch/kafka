# frozen_string_literal: true

require "fiddle"
require "kafka/poller"

module Kafka
  class Producer
    require "kafka/producer/delivery_report"

    # Initialize a new Producer for the configured cluster.
    #
    # @param config [Config]
    def initialize(config)
      # Keep a reference to the config to ensure callbacks are not garbage
      # collected. The client below takes ownership of the config.
      @config = config.native

      # Configure callbacks
      @config.set_dr_msg_cb(&method(:on_delivery_report))
      @config.set_error_cb(&method(:on_error))

      @client = ::Kafka::FFI::Producer.new(@config)

      # Maintains a list of in-flight deliveries that we're waiting for reports
      # for. If we don't, it is possible that Ruby will garbage collect them
      # before on_delivery_report is called causing memory corruption or
      # segfaults.
      @in_flight = []

      # Periodically call poll on the client to ensure callbacks are fired.
      @poller = Poller.new(@client)
    end

    def produce(topic, payload, key: nil, partition: nil, headers: nil, timestamp: nil)
      report = DeliveryReport.new
      @in_flight << report

      @client.produce(topic, payload, key: key, partition: partition, headers: headers, timestamp: timestamp, opaque: report)

      if block_given?
        yield(report)
      else
        report
      end
    rescue
      @in_flight.delete(report)
      raise
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
      report = Fiddle::Pointer.new(message.opaque.to_i).to_value
      report.done(message)

      @in_flight.delete(report)
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
