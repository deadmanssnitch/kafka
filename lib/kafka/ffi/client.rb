# frozen_string_literal: true

require "ffi"
require "kafka/config"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  # Client is a handle to a configured librdkafka instance that begins
  # operation once created. Client is an abstract class and will provide either
  # a Consumer or Producer based on the type being created. Each Client
  # instance can either produce or consume messages to / from topics and cannot
  # do both.
  #
  # @see Consumer
  # @see Producer
  #
  # @note Naming this is hard and librdkafka primarily just refers to it as "a
  #   handle" to an instance. It's more akin to an internal service and this
  #   Client talks the API to that service.
  class Client < OpaquePointer
    require "kafka/ffi/consumer"
    require "kafka/ffi/producer"

    # Create a new Client of type with the given configuration.
    #
    # @param type [:consumer, :producer] Type of Kafka instance to create.
    # @param config [nil] Use librdkafka default config
    # @param config [Config, Kafka::Config] Configuration for the instance.
    # @param config [Hash{[String, Symbol] => [String, Integer, nil, Boolean]}]
    #   Configuration options for the instance.
    #
    # @return [Consumer, Producer]
    def self.new(type, config = nil)
      error = ::FFI::MemoryPointer.new(:char, 512)

      # Convenience for passing in a Kafka::Config instead of building a
      # Kafka::FFI::Config since Kafka::Config provides a way to create a
      # config from a Hash.
      config =
        case config
        when Config, nil     then config
        when ::Kafka::Config then config.to_ffi
        when Hash            then ::Kafka::Config.new(config).to_ffi
        else
          raise ArgumentError, "config must be on of nil, Config, ::Kafka::Config, or Hash"
        end

      client = Kafka::FFI.rd_kafka_new(type, config, error, error.size)
      if client.nil?
        raise Error, error.read_string
      end

      if config
        # Store a reference to the config on the Client instance. We do this to
        # tie the Config's lifecycle to the Client instance in Ruby since they
        # are already tied in librdkafka. This ensures that any Ruby objects
        # referenced in the config (like callbacks) are not garbage collected.
        #
        # Using instance_variable_set to avoid exposing an API method that
        # could cause confusion from end users since the config cannot be
        # changed after initialization.
        client.instance_variable_set(:@config, config)
      end

      client
    end

    def self.from_native(ptr, _ctx)
      if !ptr.is_a?(::FFI::Pointer)
        raise TypeError, "from_native can only convert from a ::FFI::Pointer to #{self}"
      end

      # Converting from a null pointer should return nil. Likely this was
      # caused by rd_kafka_new returning an error and a NULL pointer for the
      # Client.
      if ptr.null?
        return nil
      end

      # Build a temporary Client to pass to rd_kafka_type. There is a bit of a
      # chicken and egg problem here. We can't create the final class until
      # after we know the type. But for type safety we want to pass a Client.
      cfg = allocate
      cfg.send(:initialize, ptr)
      type = ::Kafka::FFI.rd_kafka_type(cfg)

      klass =
        case type
        when :producer then Producer
        when :consumer then Consumer
        else
          raise ArgumentError, "unknown Kafka client type: #{type}"
        end

      client = klass.allocate
      client.send(:initialize, ptr)
      client
    end

    def initialize(ptr)
      super(ptr)

      @topics = {}
    end

    # Retrive the current configuration used by Client.
    #
    # @note The returned config is read-only and tied to the lifetime of the
    #   Client. Don't try to modify or destroy the config.
    def config
      ::Kafka::FFI.rd_kafka_conf(self)
    end

    # Retrieve the Kafka handle name.
    #
    # @return [String] handle / client name
    def name
      ::Kafka::FFI.rd_kafka_name(self)
    end

    # Retrieves the Client's Cluster ID
    #
    # @note requires config `api.version.request` set to true
    def cluster_id
      id = ::Kafka::FFI.rd_kafka_clusterid(self)

      if id.null?
        return nil
      end

      id.read_string
    ensure
      if !id.null?
        ::Kafka::FFI.rd_kafka_mem_free(self, id)
      end
    end

    # Retrieves the current Controller ID as reported by broker metadata.
    #
    # @note requires config `api.version.request` set to true
    #
    # @param timeout [Integer] Maximum time to wait in milliseconds. Specify 0
    #   for a non-blocking call.
    #
    # @return [Integer] controller broker id or -1 if no ID could be retrieved
    #   before the timeout.
    def controller_id(timeout: 1000)
      ::Kafka::FFI.rd_kafka_controllerid(self, timeout)
    end

    # Create or fetch the Topic with the given name. The first time topic is
    # called for a given name, a configuration can be passed for the topic.
    #
    # @note The returned Topic is owned by the Client and will be destroyed
    #   when the Client is destroyed.
    #
    # @param name [String] Name of the topic
    # @param config [TopicConfig, nil] Config options for the topic. This can
    #   only be passed for the first call of `topic` per topic name since a
    #   Topic can only be configured at creation.
    #
    # @raise [Kafka::ResponseError] Error occurred creating the topic
    # @raise [TopicAlreadyConfiguredError] Passed a config for a topic that has
    #   already been configured.
    #
    # @return [Topic] Topic instance
    #   error.
    def topic(name, config = nil)
      topic = @topics[name]
      if topic
        if config
          # Make this an exception because it's probably a programmer error
          # that _should_ only primarily happen during development due to
          # misunderstanding the semantics.
          raise TopicAlreadyConfigured, "#{name} was already configured"
        end

        return topic
      end

      # @todo - Keep list of topics and manage their lifecycle?
      topic = ::Kafka::FFI.rd_kafka_topic_new(self, name, config)
      if topic.nil?
        raise ::Kafka::ResponseError, ::Kafka::FFI.rd_kafka_last_error
      end

      @topics[name] = topic
      topic
    end

    # Polls for events on the the Client, causing callbacks to be fired. This
    # is used by both the Producer and Consumer to ensure callbacks are
    # processed in a timely manor.
    #
    # @note Do not call in a Consumer after poll_set_consumer has been called.
    #
    # @param timeout [Integer] Time in milliseconds to wait for an event.
    #    0 - Non-blocking call, returning immediately if there are no events.
    #   -1 - Wait indefinately for an event.
    #
    # @return [Integer] Number of events served
    def poll(timeout: 250)
      ::Kafka::FFI.rd_kafka_poll(self, timeout)
    end

    # Pause producing or consuming of the provided list of partitions. The list
    # is updated to include any errors.
    #
    # @param list [TopicPartitionList] Set of partitions to pause
    #
    # @raise [Kafka::ResponseError] Invalid request
    #
    # @return [TopicPartitionList] List of partitions with errors set for any
    #   of the TopicPartitions that failed.
    def pause_partitions(list)
      err = ::Kafka::FFI.rd_kafka_pause_partitions(self, list)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      list
    end

    # Resume producing or consuming of the provided list of partitions.
    #
    # @param list [TopicPartitionList] Set of partitions to unpause
    #
    # @raise [Kafka::ResponseError] Invalid request
    #
    # @return [TopicPartitionList] List of partitions with errors set for any
    #   of the TopicPartitions that failed.
    def resume_partitions(list)
      err = ::Kafka::FFI.rd_kafka_resume_partitions(self, list)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      list
    end

    # rubocop:disable Naming/AccessorMethodName

    # Get a reference to the main librdkafka event queue. This is the queue
    # that is served by rd_kafka_poll.
    #
    # @note Application must call #destroy on this queue when finished.
    #
    # @return [Queue] Main client Event queue
    def get_main_queue
      ::Kafka::FFI.rd_kafka_queue_get_main(self)
    end

    # Get a reference to the background thread queue. The background queue is
    # automatically polled by librdkafka and is fully managed internally.
    #
    # @note The returned Queue must not be polled, forwarded, or otherwise
    #   manage by the application. It may only be used as the destination queue
    #   passed to queue-enabled APIs.
    #
    # @note The caller must call #destroy on the Queue when finished with it
    #
    # @return [Queue] Background queue
    # @return [nil] Background queue is disabled
    def get_background_queue
      ::Kafka::FFI.rd_kafka_queue_get_background(self)
    end

    # Forward librdkafka and debug logs to the specified queue. This allows the
    # application to serve logg callbacks in its thread of choice.
    #
    # @param dest [Queue] Destination Queue for logs
    # @param dest [nil] Forward logs to the Client's main queue
    #
    # @raise [Kafka::ResponseError] Error setting the log Queue
    def set_log_queue(dest)
      err = ::Kafka::FFI.rd_kafka_set_log_queue(self, dest)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      nil
    end

    # rubocop:enable Naming/AccessorMethodName

    # Query the broker for the oldest and newest offsets for the partition.
    #
    # @param topic [String] Name of the topic to get offsets for
    # @param partition [int] Partition of the topic to get offsets for
    #
    # @raise [Kafka::ResponseError] Error that occurred retrieving offsets
    #
    # @return [Range] Range of known offsets
    def query_watermark_offsets(topic, partition, timeout: 1000)
      low  = ::FFI::MemoryPointer.new(:int64)
      high = ::FFI::MemoryPointer.new(:int64)

      err = ::Kafka::FFI.rd_kafka_query_watermark_offsets(self, topic, partition, low, high, timeout)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      Range.new(low.read_int64, high.read_int64, false)
    end

    # Look up the offsets for the given partition by timestamp. The offset for
    # each partition will be the earliest offset whose timestamp is greater
    # than or equal to the timestamp set in the TopicPartitionList.
    #
    # @param list [TopicPartitionList] List of TopicPartitions to fetch offsets
    #   for. The TopicPartitions in the list will be modified based on the
    #   results of the query.
    #
    # @raise [Kafka::ResponseError] Invalid request
    #
    # @return [TopicPartitionList] List of topics with offset set.
    def offsets_for_times(list, timeout: 1000)
      if list.nil?
        raise ArgumentError, "list cannot be nil"
      end

      err = ::Kafka::FFI.rd_kafka_offsets_for_times(self, list, timeout)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      list
    end

    # Retrieve metadata from the Kafka cluster
    #
    # @param local_only [Boolean] Only request info about locally known topics,
    #   don't query all topics in the cluster.
    # @param topic [String, Topic] Only request info about this topic.
    # @param timeout [Integer] Request timeout in milliseconds
    #
    # @raise [Kafka::ResponseError] Error retrieving metadata
    #
    # @return [Metadata] Details about the state of the cluster.
    def metadata(local_only: false, topic: nil, timeout: 1000)
      ptr = ::FFI::MemoryPointer.new(:pointer)

      # Need to use a Topic reference if asking for only information about a
      # single topic.
      if topic.is_a?(String)
        topic = self.topic(topic)
      end

      err = ::Kafka::FFI.rd_kafka_metadata(self, local_only, topic, ptr, timeout)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      Kafka::FFI::Metadata.new(ptr.read_pointer)
    ensure
      ptr.free
    end

    # List and describe client groups in the cluster.
    #
    # @note Application must call #destroy to release the list when done
    #
    # @raise [Kafka::ResponseError] Error occurred receiving group details
    #
    # @return [Kafka::FFI::GroupList] List of consumer groups in the cluster.
    def group_list(group: nil, timeout: 1000)
      list = ::FFI::MemoryPointer.new(:pointer)

      err = ::Kafka::FFI.rd_kafka_list_groups(self, group, list, timeout)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      GroupList.new(list.read_pointer)
    ensure
      list.free
    end

    # Create a copy of the Client's default topic configuration object. The
    # caller is now responsible for ownership of the new config.
    #
    # @return [TopicConfig] Duplicate config
    def default_topic_conf_dup
      ::Kafka::FFI.rd_kafka_default_topic_conf_dup(self)
    end

    # Release all of the resources used by this Client. This may block until
    # the instance has finished it's shutdown procedure. Always make sure to
    # destory any associated resources and cleanly shutting down the instance
    # before calling destroy.
    def destroy
      if !pointer.null?
        # Clean up any cached topics before destroying the Client.
        @topics.each do |_, topic|
          ::Kafka::FFI.rd_kafka_topic_destroy(topic)
        end
        @topics.clear

        ::Kafka::FFI.rd_kafka_destroy(self)
      end
    end
  end
end
