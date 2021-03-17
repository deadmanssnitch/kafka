# frozen_string_literal: true

module Kafka::FFI
  class OauthBearerTokenRefreshEvent < Event
    # Returns the value of sasl.oauthbearer.config or nil if not applicable.
    #
    # @return [String, nil] SASL config string
    def config_string
      ::Kafka::FFI.rd_kafka_event_config_string(self)
    end
  end
end
