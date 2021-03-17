# frozen_string_literal: true

module Kafka::FFI::Admin
  class DescribeConfigsResult < ::Kafka::FFI::Event
    event_type :describe_configs

    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_DescribeConfigs_result(event)
    end

    # Get the configs requested by the DescribeConfigs operation.
    #
    # @return [Array<ConfigResource>] Config resources requested
    def resources
      count = ::FFI::MemoryPointer.new(:size_t)

      resources = ::Kafka::FFI.rd_kafka_DescribeConfigs_result_resources(self, count)
      resources = resources.read_array_of_pointer(count.read(:size_t))
      resources.map! { |r| ConfigResource.from_native(r, nil) }
    ensure
      count.free
    end
  end
end
