# frozen_string_literal: true

module Kafka::FFI::Admin
  class DescribeConfigsResult < ::Kafka::FFI::Event
    event_type :describe_configs

    def self.new(event)
      ::Kafka::FFI.rd_kafka_event_DescribeConfigs_result(event)
    end

    # Retrives the opaque object set on the AdminOptions for the request.
    #
    # @note It is the applications responsibility to call #free on the return
    #   Opaque if it is no longer needed after handling the event.
    #
    # @return [Kafka::FFI::Opaque, nil] Opaque set via AdminOptions or nil if
    #   not available.
    def opaque
      ::Kafka::FFI.rd_kafka_event_opaque(self)
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
