# frozen_string_literal: true

require "kafka/ffi/event"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI::Admin
  # DeleteGroup is an admin operation to delete a consumer group by its group
  # id.
  class DeleteGroup < ::Kafka::FFI::OpaquePointer
    def self.new(group_id)
      ::Kafka::FFI.rd_kafka_DeleteGroup_new(group_id)
    end

    # Release the resources used by the DeleteGroup. It is the application's
    # responsibility to call #destroy when it is done with the object.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_DeleteGroup_destroy(self)
      end
    end
  end
end
