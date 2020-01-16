# frozen_string_literal: true

require "ffi"
require "kafka/ffi"

module Kafka::FFI::Admin
  class Client
    def initialize(config = nil)
      # Wrap a Producer
      @client = ::Kafka::FFI::Producer.new(config)
    end

    # Create a topic with the given name, number of partitions, and number of
    # replicas per partition (replication factor). Total number of partitions
    # will be partitions x replication_factor.
    #
    # @param name [String] Name of the topic to create
    # @param partitions [Integer] Number of partitions the topic will have
    # @param replication_factor [Integer] Number of replicas per partition to
    #   have in the cluster.
    #
    # @return [nil] Create timed out
    # @return [TopicResult] Response from the cluster with details about if the
    #   topic was created or any errors.
    def create_topic(name, partitions, replication_factor, timeout: 1000)
      req = NewTopic.new(name, partitions, replication_factor)

      res = create_topics(req, timeout: timeout)
      if res
        res[0]
      end
    ensure
      req.destroy
    end

    # Create topics in the cluster with the given configuration.
    #
    # @param topics [NewTopic, Array<NewTopic>] List of topics to create on the
    #   cluster.
    # @param timeout [Integer] Time in milliseconds to way for a reply.
    #
    # @raise [ResponseError] An error occurred creating the topic(s)
    #
    # @return [nil] Create timed out
    # @return [Array<TopicResult>] Response from the cluster with details about
    #   the creation of the list of topics or any errors.
    def create_topics(topics, timeout: 1000)
      topics = Array(topics)

      # CreateTopic wants an array of topics
      list = ::FFI::MemoryPointer.new(:pointer, topics.length)
      list.write_array_of_pointer(topics.map(&:pointer))

      queue = ::Kafka::FFI::Queue.new(@client)

      # TODO: AdminOption (nil placeholder)
      ::Kafka::FFI.rd_kafka_CreateTopics(@client, list, topics.length, nil, queue)

      # @todo Need to retrieve the rd_kafka_topic_result_t to handle or
      #   propogate any errors.
      queue.poll(timeout: timeout) do |event|
        get_topic_results(event)
      end
    ensure
      list.free
      queue.destroy if queue
    end

    def get_topic_results(event)
      count = ::FFI::MemoryPointer.new(:size_t)

      results =
        case event.type
        when :create_topics
          ::Kafka::FFI.rd_kafka_CreateTopics_result_topics(event, count)
        when :delete_topics
          ::Kafka::FFI.rd_kafka_DeleteTopics_result_topics(event, count)
        else
          raise ArgumentError, "unable to map #{event.class} to TopicResults"
        end

      results = results.read_array_of_pointer(count.read(:size_t))
      results.map! { |p| TopicResult.new(p) }
    ensure
      count.free
    end

    # Delete the topic with the given name
    #
    # @param name [String] Name of the topic to delete
    # @param timeout [Integer] Time to wait in milliseconds for the deletion to
    #   complete.
    #
    # @return [nil] Delete timed out
    # @return [TopicResult] Response from the cluster with details about the
    #   deletion or any errors.
    def delete_topic(name, timeout: 1000)
      req = DeleteTopic.new(name, timeout: timeout)
      res = delete_topics(req)

      if res
        res[0]
      end
    ensure
      req.destroy
    end

    # Delete a list of Topics
    #
    # @param topics [DeleteTopic] List of topics to delete
    # @param timeout [Integer] Time to wait in milliseconds for the deletion to
    #   complete.
    #
    # @return [nil] Delete timed out
    # @return [Array<TopicResult>] Response from the cluster with details about
    #   the deletion of the list of topics or any errors.
    def delete_topics(topics, timeout: 1000)
      topics = Array(topics)

      # CreateTopic wants an array of topics
      list = ::FFI::MemoryPointer.new(:pointer, topics.length)
      list.write_array_of_pointer(topics.map(&:pointer))

      queue = ::Kafka::FFI::Queue.new(@client)

      # TODO: AdminOption (nil placeholder)
      ::Kafka::FFI.rd_kafka_DeleteTopics(@client, list, topics.length, nil, queue)

      queue.poll(timeout: timeout) do |event|
        get_topic_results(event)
      end
    ensure
      list.free
      queue.destroy if queue
    end

    # Retrieve metadata for the cluster
    #
    # @see Kafka::FFI::Client#metadata
    #
    # @return [Metadata]
    def metadata(local_only: false, topic: nil, timeout: 1000)
      @client.metadata(local_only: local_only, topic: topic, timeout: timeout)
    end

    # Destroy the Client, releasing all used resources back to the system. It
    # is the application's responsbility to call #destroy when done with the
    # client.
    def destroy
      @client.destroy
    end
  end
end
