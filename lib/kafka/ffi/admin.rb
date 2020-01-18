# frozen_string_literal: true

require "kafka/ffi"

module Kafka::FFI
  module Admin
    require "kafka/ffi/admin/error"
    require "kafka/ffi/admin/client"
    require "kafka/ffi/admin/new_topic"
    require "kafka/ffi/admin/delete_topic"
    require "kafka/ffi/admin/topic_result"
    require "kafka/ffi/admin/admin_options"
  end
end
