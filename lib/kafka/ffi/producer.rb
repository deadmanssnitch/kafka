# frozen_string_literal: true

require "ffi"
require "kafka/ffi/client"

module Kafka::FFI
  class Producer < Kafka::FFI::Client
    native_type :pointer

    def self.new(config = nil)
      super(:producer, config)
    end
  end
end
