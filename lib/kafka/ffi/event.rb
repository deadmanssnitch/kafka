# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Event < OpaquePointer
    def destroy
    end
  end
end
