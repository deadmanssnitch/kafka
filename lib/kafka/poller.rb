# frozen_string_literal: true

module Kafka
  # @private
  #
  # Niceties around a Thread to call Client#poll at a regular interval. This is
  # required in the Producer and optional in the Consumer when
  # poll_set_consumer is not used.
  class Poller < Thread
    def initialize(client)
      @client = client
      @run = true

      self.abort_on_exception = true

      super do
        while @run
          @client.poll
        end
      end
    end

    def stop
      @run = false
      join
    end
  end
end
