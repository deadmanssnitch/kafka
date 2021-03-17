# frozen_string_literal: true

require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  class DeleteRecords < ::Kafka::FFI::OpaquePointer
    def self.new(tpl)
      ::Kafka::FFI.rd_kafka_DeleteRecords_new(tpl)
    end

    # Release the resources used by the DeleteRecords. It is the application's
    # responsibility to call #destroy when it is done with the object.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_DeleteRecords_destroy(self)
      end
    end
  end
end
