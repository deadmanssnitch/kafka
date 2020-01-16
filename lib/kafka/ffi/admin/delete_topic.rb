# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class DeleteTopic < ::Kafka::FFI::OpaquePointer
    def self.new(topic)
      ::Kafka::FFI.rd_kafka_DeleteTopic_new(topic)
    end

    # Release the resources used by the DeleteTopic. It is the application's
    # responsibility to call #destroy when it is done with the object.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_DeleteTopic_destroy(self)
      end
    end
  end
end
