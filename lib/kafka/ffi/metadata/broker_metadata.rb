# frozen_string_literal: true

class Kafka::FFI::Metadata
  class BrokerMetadata < ::FFI::Struct
    layout(
      :id,   :int32,
      :host, :string,
      :port, :int
    )

    # Returns the Broker's cluster ID
    #
    # @return [Integer] Broker ID
    def id
      self[:id]
    end

    # Returns the hostname of the Broker
    #
    # @return [String] Broker hostname
    def host
      self[:host]
    end

    # Returns the port used to connect to the Broker
    #
    # @return [Integer] Broker port
    def port
      self[:port]
    end
  end
end
