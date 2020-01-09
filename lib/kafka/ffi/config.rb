# frozen_string_literal: true

require "ffi"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Config < OpaquePointer
    def self.new(ptr = nil)
      if ptr.is_a?(::FFI::Pointer)
        return super(ptr)
      end

      Kafka::FFI.rd_kafka_conf_new
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
      result = ::Kafka::FFI.rd_kafka_conf_set(self, key, value, error, error.size)

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
      err = ::Kafka::FFI.rd_kafka_conf_get(self, key, ::FFI::Pointer::NULL, size)
      if err != :ok
        return err
      end

      # Allocate a string long enough to contain the whole value.
      value = ::FFI::MemoryPointer.new(:char, size.read(:size_t))
      err = ::Kafka::FFI.rd_kafka_conf_get(self, key, value, size)
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
    # @return [Config] Duplicated config
    def dup
      ::Kafka::FFI.rd_kafka_conf_dup(self)
    end

    # Duplicate the config but do not copy any config options that match the
    # filtered keys.
    def dup_filter(*filter)
      ptr = ::FFI::MemoryPointer.new(:pointer, filter.length)

      ptr.write_array_of_pointer(
        filter.map { |str| ::FFI::MemoryPointer.from_string(str) },
      )

      ::Kafka::FFI.rd_kafka_conf_dup_filter(self, filter.length, ptr)
    ensure
      ptr.free
    end

    # rubocop:disable Naming/AccessorMethodName

    # Enable event sourcing. Convenience method to set the `enabled_events`
    # option as an integer.
    #
    # @example Set events using event symbol names
    #   config.set_events([ :delivery, :log, :fetch ])
    #
    # @example Set events using event constants
    #   config.set_events([ RD_KAFKA_EVENT_DR, RD_KAFKA_EVENT_LOG ])
    #
    # @param events_mask [Integer, Array<Symbol, Integer>] Bitmask of events to
    #   enable during queue poll.
    def set_events(events_mask)
      mask = events_mask

      # Support setting events
      if events_mask.is_a?(Array)
        mask = 0
        enum = ::Kafka::FFI.enum_type(:event_type)

        events_mask.each do |val|
          case val
          when Integer then mask |= val
          when Symbol  then mask |= (enum[val] || 0)
          end
        end
      end

      ::Kafka::FFI.rd_kafka_conf_set_events(self, mask)
    end
    # rubocop:enable Naming/AccessorMethodName

    # Free all resources used by the config.
    #
    # @note Never call #destroy on a Config that has been passed to
    #   Kafka::FFI.rd_kafka_new since the handle will take ownership of the
    #   config.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_conf_destroy(self)
      end
    end
  end
end
