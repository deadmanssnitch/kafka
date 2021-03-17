# frozen_string_literal: true

require "kafka/ffi/event"

module Kafka::FFI
  module Admin
    require "kafka/ffi/admin/group_result"
    require "kafka/ffi/admin/topic_result"
    require "kafka/ffi/admin/admin_options"
    require "kafka/ffi/admin/config_entry"
    require "kafka/ffi/admin/config_resource"

    require "kafka/ffi/admin/alter_configs_result"
    require "kafka/ffi/admin/describe_configs_result"
    require "kafka/ffi/admin/create_topics_result"
    require "kafka/ffi/admin/create_partitions_result"
    require "kafka/ffi/admin/delete_topics_result"
    require "kafka/ffi/admin/delete_groups_result"
    require "kafka/ffi/admin/delete_records_result"
    require "kafka/ffi/admin/delete_consumer_group_offsets_result"

    require "kafka/ffi/admin/new_topic"
    require "kafka/ffi/admin/new_partitions"
    require "kafka/ffi/admin/delete_topic"
    require "kafka/ffi/admin/delete_group"
    require "kafka/ffi/admin/delete_records"
    require "kafka/ffi/admin/delete_consumer_group_offsets"
  end
end
