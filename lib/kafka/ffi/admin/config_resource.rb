# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class ConfigResource < ::Kafka::FFI::OpaquePointer
    # Create a new ConfigResource
    #
    # @example Build ConfigResource for a topic
    #   ConfigResource.new(:topic, "events")
    #
    # @example Build ConfigResource for a broker
    #   ConfigResource.new(:broker, broker_id)
    #
    # @see ffi.rb resource_type enum
    #
    # @param type [:broker, :topic, :group] Type of config resource
    # @param name [String] Name of resource (broker_id, topic name, etc...)
    def self.new(type, name)
      ::Kafka::FFI.rd_kafka_ConfigResource_new(type, name)
    end

    # Set configuration name and value pair
    #
    # @note This will overwrite the current value
    #
    # @param name [String] Config option name
    # @param value [nil] Revert config to default
    # @param value [String] Value to set config option to
    #
    # @raise [Kafka::ResponseError] Invalid input
    def set_config(name, value)
      err = ::Kafka::FFI.rd_kafka_ConfigResource_set_config(self, name, value)
      if err != :ok
        raise ::Kafka::ResponseError, err
      end

      nil
    end

    # Retrieve an array of ConfigEntry from the resource.
    #
    # @return [Array<ConfigEntry>] Config entries for the resource
    def configs
      count = ::FFI::MemoryPointer.new(:pointer)

      configs = ::Kafka::FFI.rd_kafka_ConfigResource_configs(self, count)
      if configs.null?
        return nil
      end

      configs = configs.read_array_of_pointer(count.read(:size_t))
      configs.map! { |p| ConfigEntry.from_native(p, nil) }
    ensure
      count.free
    end

    # Returns the type of the resource
    #
    # @see ffi.rb resource_type enum
    #
    # @return [Symbol] Type of config resource
    def type
      ::Kafka::FFI.rd_kafka_ConfigResource_type(self)
    end

    # Returns the config option name
    #
    # @return [String] Name of the config
    def name
      ::Kafka::FFI.rd_kafka_ConfigResource_name(self)
    end

    # Returns the response error received from an AlterConfigs request.
    #
    # @note Only set when ConfigResource was returned from AlterConfigs.
    #
    # @return [nil] No error
    # @return [Kafka::ResponseError] AlterConfig request error
    def error
      err = ::Kafka::FFI.rd_kafka_ConfigResource_error(self)
      err == :ok ? nil : ::Kafka::ResponseError.new(err)
    end

    # Returns a string describing the error received for this resource during
    # an AlterConfigs request.
    #
    # @note Only set when ConfigResource was returned from AlterConfigs.
    #
    # @return [nil] No error
    # @return [String] AlterConfig request error
    def error_string
      ::Kafka::FFI.rd_kafka_ConfigResource_error_string(self)
    end

    # Destroy the ConfigResource, returning its resources back to the system.
    def destroy
      ::Kafka::FFI.rd_kafka_ConfigResource_destroy(self)
    end
  end
end
