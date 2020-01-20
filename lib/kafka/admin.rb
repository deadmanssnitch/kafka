# frozen_string_literal: true

require "ffi"
require "kafka/ffi"

module Kafka
  # Admin provides a client for accessing the rdkafka Admin API to make changes
  # to the cluster. The API provides was to create topics, delete topics, add
  # new partitions for a topic, and manage configs
  class Admin
    # Create a new Admin client for accessing the librdkafka Admin API.
    #
    # @param config [Kafka::Config] Cluster config
    def initialize(config = nil)
      # Wrap a Producer since it appears to allocate the fewest resources.
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
    # @param wait [Boolean] Wait up to timeout milliseconds for topic creation
    #   to propogate to the cluster before returning.
    # @param validate [Boolean] Only validate the request
    # @param timeout [Integer] Time to wait in milliseconds for each operation
    #   to complete. Total request execution time may be longer than timeout
    #   due to multiple operations being done. Defaults to `socket.timeout.ms`
    #   config setting.
    #
    # @return [nil] Create timed out
    # @return [TopicResult] Response from the cluster with details about if the
    #   topic was created or any errors.
    def create_topic(name, partitions, replication_factor, wait: true, validate: false, timeout: nil)
      req = ::Kafka::FFI::Admin::NewTopic.new(name, partitions, replication_factor)
      opts = new_options(:create_topics, wait: wait, validate: validate, timeout: timeout)

      res = @client.create_topics(req, options: opts)
      if res
        res[0]
      end
    ensure
      opts.destroy
      req.destroy
    end

    # Delete the topic with the given name
    #
    # @param name [String] Name of the topic to delete
    #
    # @param wait [Boolean] Wait up to timeout milliseconds for topic creation
    #   to propogate to the cluster before returning.
    # @param validate [Boolean] Only validate the request
    # @param timeout [Integer] Time to wait in milliseconds for each operation
    #   to complete. Total request execution time may be longer than timeout
    #   due to multiple operations being done. Defaults to `socket.timeout.ms`
    #   config setting.
    #
    # @return [nil] Delete timed out
    # @return [TopicResult] Response from the cluster with details about the
    #   deletion or any errors.
    def delete_topic(name, wait: true, validate: false, timeout: nil)
      req = ::Kafka::FFI::Admin::DeleteTopic.new(name)
      opts = new_options(:create_topics, wait: wait, validate: validate, timeout: timeout)

      res = @client.delete_topics(req, options: opts)
      if res
        res[0]
      end
    ensure
      opts.destroy
      req.destroy
    end

    # Get current config settings for the resource.
    #
    # @example Get configuration for a topic
    #   describe_config(:topic, "events")
    #
    # @param type [:broker, :topic, :group] Type of resource
    # @param name [String] Name of the resource
    #
    # @return [ConfigResource]
    def describe_config(type, name, wait: true, validate: false, timeout: nil)
      req = ::Kafka::FFI::Admin::ConfigResource.new(type, name)
      opts = new_options(:create_topics, wait: wait, validate: validate, timeout: timeout)

      res = @client.describe_configs(req, options: opts)
      if res
        res[0]
      end
    ensure
      opts.destroy
      req.destroy
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

    private

    def new_options(api, wait: false, timeout: nil, validate: false)
      options = ::Kafka::FFI::Admin::AdminOptions.new(@client, api)

      # Request timeout defaults to socket.timeout.ms unless set. We use the
      # timeout for both request_timeout and operation timeout when not set. It
      # simplifies the API even if it is a bad assumption.
      if timeout.nil?
        timeout = @client.config.get("socket.timeout.ms").to_i
      end

      options.set_request_timeout(timeout)
      options.set_validate_only(validate)

      if wait
        options.set_operation_timeout(timeout)
      end

      options
    end
  end
end
