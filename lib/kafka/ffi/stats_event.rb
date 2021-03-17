# frozen_string_literal: true

module Kafka::FFI
  class StatsEvent < Event
    event_type :stats

    # Extracts stats from the event
    #
    # @return [String] JSON encoded stats information.
    def stats
      ::Kafka::FFI.rd_kafka_event_stats(self)
    end
  end
end
