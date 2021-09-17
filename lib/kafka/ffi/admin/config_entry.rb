# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class ConfigEntry < ::Kafka::FFI::OpaquePointer
    # Returns the configuration property name
    #
    # @return [String] Configuration property name
    def name
      ::Kafka::FFI.rd_kafka_ConfigEntry_name(self)
    end

    # Returns the configuration value
    #
    # @return [nil] Value is sensitive or unset
    # @return [String] Configuration value
    def value
      ::Kafka::FFI.rd_kafka_ConfigEntry_value(self)
    end

    # Returns the source of the config
    #
    # @see ffi.rb config_source
    #
    # @return [Symbol] Source of the config
    def source
      ::Kafka::FFI.rd_kafka_ConfigEntry_source(self)
    end

    # List of synonyms for the config entry
    #
    # @return [nil] ConfigEntry was not returned by DescribeConfigs
    # @return [Array<ConfigEntry>] Set of synonyms for the config
    def synonyms
      count = ::FFI::MemoryPointer.new(:pointer)

      entries = ::Kafka::FFI.rd_kafka_ConfigEntry_synonyms(self, count)
      if entries.null?
        return nil
      end

      entries.read_array_of_pointer(count.read(:size_t)).map do |ptr|
        ConfigEntry.new(ptr)
      end
    ensure
      count.free
    end

    # Returns true if the config property is read-only on the broker. Only
    # returns a boolean when called on a ConfigEntry from a DescribeConfigs
    # result.
    #
    # @return [nil] ConfigEntry was not returned by DescribeConfigs
    # @return [Boolean] If the property is read only
    def read_only?
      val = ::Kafka::FFI.rd_kafka_ConfigEntry_is_read_only(self)
      val == -1 ? nil : val == 1
    end

    # Returns true if the config property is set to its default. Only returns a
    # boolean when use on a ConfigEntry from a DescribeConfigs result.
    #
    # @return [nil] ConfigEntry was not returned by DescribeConfigs
    # @return [Boolean] If the property is set to default
    def default?
      val = ::Kafka::FFI.rd_kafka_ConfigEntry_is_default(self)
      val == -1 ? nil : val == 1
    end

    # Returns true if the config property is sensitive. Only returns a boolean
    # when use on a ConfigEntry from a DescribeConfigs result.
    #
    # @return [nil] ConfigEntry was not returned by DescribeConfigs
    # @return [Boolean] If the property is set to default
    def sensitive?
      val = ::Kafka::FFI.rd_kafka_ConfigEntry_is_sensitive(self)
      val == -1 ? nil : val == 1
    end

    # Returns true if the entry is a synonym for another config option.
    #
    # @return [Boolean]
    def synonym?
      ::Kafka::FFI.rd_kafka_ConfigEntry_is_sensitive(self) == 1
    end

    # Alias Ruby style predicates (e.g. read_only?) to their rdkafka method
    # names (e.g. is_read_only).
    alias is_read_only read_only?
    alias is_default   default?
    alias is_sensitive sensitive?
    alias is_synonym   synonym?
  end
end
