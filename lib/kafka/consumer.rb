# frozen_string_literal: true

require "kafka/poller"

module Kafka
  class Consumer
    # Returns the backing Kafka::FFI::Consumer.
    #
    # @DANGER Using the backing Consumer means being aware of memory management
    #   and could leave the producer in a bad state. Make sure you know what
    #   you're doing.
    #
    # @return [Kafka::FFI::Consumer]
    attr_reader :client

    # @param config [Kafka::Config]
    def initialize(config)
      # Initialize the client
      @client = Kafka::FFI::Consumer.new(config)

      # Event loop polling for events so callbacks are fired.
      @poller = Poller.new(@client)
    end

    # Subscribe the consumer to the given list of topics. Once the
    # subscriptions have become active, calls to #poll with yield messages for
    # the subscribe topics.
    #
    # @param topic [String, Array<String>] Topics to subscribe to
    def subscribe(topic, *rest)
      @client.subscribe(topic, *rest)
    end

    # Retrieves the set of topic + partition assignments for the consumer.
    #
    # @example
    #   consumer.assignment # => { "topic" => [1,2,3] }
    #
    # @return [Hash{String => Array<Integer>}] List of partition assignments
    #   keyed by the topic name.
    def assignments
      @client.assignment
    end

    # Poll the consumer for waiting message.
    #
    # @param timeout [Integer] Time to wait in milliseconds for a message to be
    #   available.
    def poll(timeout: 250, &block)
      @client.consumer_poll(timeout, &block)
    end

    # @param msg [Consumer::Message]
    def commit(msg, async: false)
      list = Kafka::FFI::TopicPartitionList.new(1)

      list.add(msg.topic, msg.partition)
      list.set_offset(msg.topic, msg.partition, msg.offset + 1)

      @client.commit(list, async)
    ensure
      list.destroy
    end

    # Gracefully shutdown the consumer and it's connections.
    #
    # @note After calling #close it is unsafe to call any other method on the
    #   Consumer.
    def close
      # @see https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md#high-level-kafkaconsumer
      @poller.stop

      # Leave the consumer group, commit and hanging offsets, etc...
      @client.close

      # Dispatch any remaining callbacks or events.
      @client.poll

      # Release resources back to the system.
      @client.destroy
    end
  end
end
