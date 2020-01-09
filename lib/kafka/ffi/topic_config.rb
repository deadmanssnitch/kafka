# frozen_string_literal: true

require "ffi"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  # TopicConfig can be passed to Topic.new to configure how the client
  # interacts with the Topic.
  class TopicConfig < OpaquePointer
    def self.new(ptr = nil)
      if ptr.is_a?(::FFI::Pointer)
        return super(ptr)
      end

      Kafka::FFI.rd_kafka_topic_conf_new
    end

    # Set the config option at `key` to `value`. The configuration options
    # match those used by librdkafka (and the Java client).
    #
    # @see https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md
    #
    # @param key [String] Configuration key
    # @param value [String] Value to set
    #
    # @raise [Kafka::FFI::UnknownConfigKey]
    # @raise [Kafka::FFI::InvalidConfigValue]
    def set(key, value)
      key = key.to_s
      value = value.to_s

      error = ::FFI::MemoryPointer.new(:char, 512)
      result = ::Kafka::FFI.rd_kafka_topic_conf_set(self, key, value, error, error.size)

      # See config_result enum in ffi.rb
      case result
      when :ok
        nil
      when :unknown
        raise Kafka::FFI::UnknownConfigKey.new(key, value, error.read_string)
      when :invalid
        raise Kafka::FFI::InvalidConfigValue.new(key, value, error.read_string)
      end
    ensure
      error.free if error
    end

    # Get the current config value for the given key.
    #
    # @param key [String] Config key to fetch the setting for.
    #
    # @return [String, :unknown] Value for the key or :unknown if not already
    #   set.
    def get(key)
      key = key.to_s

      # Will contain the size of the value at key
      size = ::FFI::MemoryPointer.new(:size_t)

      # Make an initial request for the size of buffer we need to allocate.
      # When trying to make a guess at the potential size the code would often
      # segfault due to rd_kafka_conf_get reallocating the buffer.
      err = ::Kafka::FFI.rd_kafka_topic_conf_get(self, key, ::FFI::Pointer::NULL, size)
      if err != :ok
        return err
      end

      # Allocate a string long enough to contain the whole value.
      value = ::FFI::MemoryPointer.new(:char, size.read(:size_t))
      err = ::Kafka::FFI.rd_kafka_topic_conf_get(self, key, value, size)
      if err != :ok
        return err
      end

      value.read_string
    ensure
      size.free if size
      value.free if value
    end

    # Duplicate the current config
    #
    # @return [TopicConfig] Duplicated config
    def dup
      ::Kafka::FFI.rd_kafka_topic_conf_dup(self)
    end

    # Sets a custom partitioner callback that is called for each message to
    # determine which partition to publish the message to.
    #
    # @example Random partitioner
    #   set_partitioner_cb do |_topic, _key, parts|
    #     rand(parts)
    #   end
    #
    # @see "partitioner" config option for predefined strategies
    #
    # @yield [topic, key, partition_count]
    # @yieldparam topic [Topic] Topic the message is being published to
    # @yieldparam key [String] Partitioning key provided when publishing
    # @yieldparam partition_count [Integer] Number of partitions the topic has
    # @yieldreturn [Integer] The partition to publish the message to
    def set_partitioner_cb
      if !block_given?
        raise ArgumentError, "set_partitioner_cb must be called with a block"
      end

      # @todo How do we guarantee the block does not get garbage collected?
      # @todo Support opaque pointers?
      cb = ::FFI::Function.new(:int, [:pointer, :string, :size_t, :int32, :pointer, :pointer]) do |topic, key, _, partitions, _, _|
        topic = Topic.new(topic)

        yield(topic, key, partitions)
      end

      ::Kafka::FFI.rd_kafka_topic_conf_set_partitioner_cb(self, cb)
    end

    # Free all resources used by the topic config.
    #
    # @note Never call #destroy on a Config that has been passed to
    #   Kafka::FFI.rd_kafka_topic_new since the handle will take ownership of
    #   the config.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_topic_conf_destroy(self)
      end
    end
  end
end
