# frozen_string_literal: true

module Kafka::FFI
  module Admin
    require "kafka/ffi/admin/result"
    require "kafka/ffi/admin/new_topic"
    require "kafka/ffi/admin/delete_topic"
    require "kafka/ffi/admin/topic_result"
    require "kafka/ffi/admin/admin_options"
    require "kafka/ffi/admin/config_entry"
    require "kafka/ffi/admin/new_partitions"
    require "kafka/ffi/admin/config_resource"
  end
end
