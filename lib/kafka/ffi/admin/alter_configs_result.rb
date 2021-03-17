# frozen_string_literal: true

require "kafka/ffi/event"

module Kafka::FFI::Admin
  class AlterConfigsResult < ::Kafka::FFI::Event
    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_AlterConfigs_result(event)
    end

    # Gets the config resources affected by the AlterConfigs operation.
    #
    # @return [Array<ConfigResource>] Config resources affected
    def resources
      count = ::FFI::MemoryPointer.new(:size_t)

      resources = ::Kafka::FFI.rd_kafka_AlterConfigs_result_resources(self, count)
      resources = resources.read_array_of_pointer(count.read(:size_t))
      resources.map! { |r| ConfigResource.from_native(r, nil) }
    ensure
      count.free
    end
  end
end
