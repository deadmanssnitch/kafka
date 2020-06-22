# frozen_string_literal: true

class Kafka::Metadata
  class Broker
    attr_reader :id
    attr_reader :host
    attr_reader :port

    # @param native [Kafka::FFI::BrokerMetadata]
    def initialize(native)
      @id = native.id
      @host = native.host
      @port = native.port
    end
  end
end
