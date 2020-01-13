# frozen_string_literal: true

require "ffi"
require "kafka/error"

module Kafka
  # Module FFI provides both a (mostly) complete set of low level function
  # calls into librdkafka as well as a set of slightly higher level
  # abstractions and objects that make working with the API easier. It is still
  # required to know enough about using librdkafka to use the abstractions
  # safely (see the introduction below).
  #
  # All exposed functions on Kafka::FFI are named to match the functions
  # exposed by librdkafka (see rdkafka.h).
  #
  # See: https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md
  # See: https://github.com/edenhill/librdkafka/blob/master/src/rdkafka.h
  module FFI
    extend ::FFI::Library

    ffi_lib [
      File.expand_path("../../ext/librdkafka.so", __dir__),
      File.expand_path("../../ext/librdkafka.dylib", __dir__),
    ]

    # kafka_type is passed to rd_kafka_new to specify the role of the
    # connection.
    #
    # @see rdkafka.h rd_kafka_type_t
    enum :kafka_type, [
      :producer, 0,
      :consumer, 1,
    ]

    # config_result is return from many operations on Config and TopicConfig.
    #
    # @see rdkafka.h rd_kafka_conf_res_t
    enum :config_result, [
      :unknown, -2, # Unknown configuration name.
      :invalid, -1, # Invalid configuration value.
      :ok, 0,       # Configuration okay
    ]

    # Response Errors
    RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS = -175
    RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS = -174
    RD_KAFKA_RESP_ERR__NO_OFFSET = -168
    RD_KAFKA_RESP_ERR__NOENT = -156
    RD_KAFKA_RESP_ERR__FATAL = -150

    # @see rdkafka.h rd_kafka_resp_err_t
    enum :error_code, [
      :ok, 0,
    ]

    # @see rdkafka.h rd_kafka_cert_type_t
    enum :cert_type, [
      :public,  0,
      :private, 1,
      :ca,      2,
      :_cnt,    3,
    ]

    # @see rdkafka.h rd_kafka_cert_enc_t
    enum :cert_enc, [
      :pkcs12, 0,
      :der,    1,
      :pem,    2,
      :_cnt,   3,
    ]

    RD_KAFKA_OFFSET_BEGINNING = -2
    RD_KAFKA_OFFSET_END       = -1
    RD_KAFKA_OFFSET_STORED    = -1000
    RD_KAFKA_OFFSET_INVALID   = -1001

    RD_KAFKA_EVENT_NONE                      =  0x00
    RD_KAFKA_EVENT_DR                        =  0x01
    RD_KAFKA_EVENT_FETCH                     =  0x02
    RD_KAFKA_EVENT_LOG                       =  0x04
    RD_KAFKA_EVENT_ERROR                     =  0x08
    RD_KAFKA_EVENT_REBALANCE                 =  0x10
    RD_KAFKA_EVENT_OFFSET_COMMIT             =  0x20
    RD_KAFKA_EVENT_STATS                     =  0x40
    RD_KAFKA_EVENT_CREATETOPICS_RESULT       =   100
    RD_KAFKA_EVENT_DELETETOPICS_RESULT       =   101
    RD_KAFKA_EVENT_CREATEPARTITIONS_RESULT   =   102
    RD_KAFKA_EVENT_ALTERCONFIGS_RESULT       =   103
    RD_KAFKA_EVENT_DESCRIBECONFIGS_RESULT    =   104
    RD_KAFKA_EVENT_OAUTHBEARER_TOKEN_REFRESH = 0x100

    # @see rd_kafka_event_type_t
    enum :event_type, [
      :none,                       RD_KAFKA_EVENT_NONE,
      :dr,                         RD_KAFKA_EVENT_DR,
      :delivery,                   RD_KAFKA_EVENT_DR, # Alias for dr (delivery report)
      :fetch,                      RD_KAFKA_EVENT_FETCH,
      :log,                        RD_KAFKA_EVENT_LOG,
      :error,                      RD_KAFKA_EVENT_ERROR,
      :rebalance,                  RD_KAFKA_EVENT_REBALANCE,
      :offset_commit,              RD_KAFKA_EVENT_OFFSET_COMMIT,
      :stats,                      RD_KAFKA_EVENT_STATS,
      :create_topics,              RD_KAFKA_EVENT_CREATETOPICS_RESULT,
      :delete_topics,              RD_KAFKA_EVENT_DELETETOPICS_RESULT,
      :create_partitions,          RD_KAFKA_EVENT_CREATEPARTITIONS_RESULT,
      :alter_configs,              RD_KAFKA_EVENT_ALTERCONFIGS_RESULT,
      :describe_configs,           RD_KAFKA_EVENT_DESCRIBECONFIGS_RESULT,
      :oauth_bearer_token_refresh, RD_KAFKA_EVENT_OAUTHBEARER_TOKEN_REFRESH,
    ]

    RD_KAFKA_MSG_STATUS_NOT_PERSISTED      = 0
    RD_KAFKA_MSG_STATUS_POSSIBLY_PERSISTED = 1
    RD_KAFKA_MSG_STATUS_PERSISTED          = 2

    # @see rdkafka.h rd_kafka_message_status
    enum :message_status, [
      :not_presisted,      RD_KAFKA_MSG_STATUS_NOT_PERSISTED,
      :possibly_persisted, RD_KAFKA_MSG_STATUS_POSSIBLY_PERSISTED,
      :persisted,          RD_KAFKA_MSG_STATUS_PERSISTED,
    ]

    typedef :int,     :timeout_ms
    typedef :int32,   :partition
    typedef :int64,   :offset
    typedef :string,  :topic
    typedef :pointer, :opaque

    # Load types after enums and constants so they're able to reference them.
    require "kafka/ffi/admin"
    require "kafka/ffi/error"
    require "kafka/ffi/event"
    require "kafka/ffi/queue"
    require "kafka/ffi/topic"
    require "kafka/ffi/client"
    require "kafka/ffi/config"
    require "kafka/ffi/message"
    require "kafka/ffi/topic_config"
    require "kafka/ffi/opaque_pointer"
    require "kafka/ffi/topic_partition"
    require "kafka/ffi/topic_partition_list"

    # Errors
    attach_function :rd_kafka_err2str, [:error_code], :string
    attach_function :rd_kafka_err2name, [:error_code], :string
    attach_function :rd_kafka_last_error, [], :error_code

    # Client
    attach_function :rd_kafka_new, [:kafka_type, Config, :pointer, :int], Client, blocking: true
    attach_function :rd_kafka_type, [Client], :kafka_type
    attach_function :rd_kafka_name, [Client], :string
    attach_function :rd_kafka_memberid, [Client], :pointer
    attach_function :rd_kafka_clusterid, [Client], :pointer
    attach_function :rd_kafka_controllerid, [Client, :timeout_ms], :int32, blocking: true
    attach_function :rd_kafka_default_topic_conf_dup, [Client], TopicConfig
    attach_function :rd_kafka_conf, [Client], Config
    attach_function :rd_kafka_poll, [Client, :timeout_ms], :int, blocking: true

    # @note This function MUST ONLY be called from within a librdkafka
    #   callback.
    # @note A callback may use this to force an immediate return to the caller
    #   that dispatched the callback without processing any further events.
    attach_function :rd_kafka_yield, [Client], :void

    # @test
    attach_function :rd_kafka_pause_partitions, [Client, TopicPartitionList.by_ref], :error_code
    # @test
    attach_function :rd_kafka_resume_partitions, [Client, TopicPartitionList.by_ref], :error_code
    # @test
    attach_function :rd_kafka_query_watermark_offsets, [Client, :string, :partition, :pointer, :pointer, :timeout_ms], :error_code, blocking: true
    # @test
    attach_function :rd_kafka_get_watermark_offsets, [Client, :string, :partition, :pointer, :pointer], :error_code
    # @test
    attach_function :rd_kafka_offsets_for_times, [Client, TopicPartitionList.by_ref, :timeout_ms], :error_code, blocking: true

    attach_function :rd_kafka_mem_free, [Client, :pointer], :void
    attach_function :rd_kafka_destroy, [Client], :void, blocking: true

    # Config
    #
    # NOTE: The following deprecated functions have not been implemented
    #   rd_kafka_conf_set_dr_cb
    #   rd_kafka_conf_set_default_topic_conf

    attach_function :rd_kafka_conf_new, [], Config
    attach_function :rd_kafka_conf_set, [Config, :string, :string, :pointer, :size_t], :config_result
    attach_function :rd_kafka_conf_get, [Config, :string, :pointer, :pointer], :config_result

    # @todo?
    # attach_function :rd_kafka_conf_set_opaque, [Config, :pointer], :void
    # attach_function :rd_kafka_opaque, [Client], :pointer

    attach_function :rd_kafka_conf_dup, [Config], Config
    attach_function :rd_kafka_conf_dup_filter, [Config, :size_t, :pointer], Config

    # @param event_type is a bitmask of RD_KAFKA_EVENT_* constants.
    attach_function :rd_kafka_conf_set_events, [Config, :event_type], :void

    callback :background_event_cb, [Client, Event, :opaque], :void
    attach_function :rd_kafka_conf_set_background_event_cb, [Config, :background_event_cb], :void

    callback :dr_msg_cb, [Client, Message.by_ref, :pointer], :void
    attach_function :rd_kafka_conf_set_dr_msg_cb, [Config, :dr_msg_cb], :void

    callback :consume_cb, [Message.by_ref, :pointer], :void
    attach_function :rd_kafka_conf_set_consume_cb, [Config, :consume_cb], :void

    callback :rebalance_cb, [Client, :error_code, TopicPartitionList.by_ref, :pointer], :void
    attach_function :rd_kafka_conf_set_rebalance_cb, [Config, :rebalance_cb], :void

    callback :offset_commit_cb, [Client, :error_code, TopicPartitionList.by_ref, :pointer], :void
    attach_function :rd_kafka_conf_set_offset_commit_cb, [Config, :offset_commit_cb], :void

    callback :error_cb, [Client, :error_code, :string, :pointer], :void
    attach_function :rd_kafka_conf_set_error_cb, [Config, :error_cb], :void

    callback :throttle_cb, [Client, :string, :int32, :int, :pointer], :void
    attach_function :rd_kafka_conf_set_throttle_cb, [Config, :throttle_cb], :void

    callback :log_cb, [Client, :int, :string, :string], :void
    attach_function :rd_kafka_conf_set_log_cb, [Config, :log_cb], :void

    callback :stats_cb, [Client, :string, :size_t, :pointer], :void
    attach_function :rd_kafka_conf_set_stats_cb, [Config, :stats_cb], :void

    callback :oauth_bearer_token_refresh_cb, [Client, :string, :pointer], :void
    attach_function :rd_kafka_conf_set_oauthbearer_token_refresh_cb, [Config, :oauth_bearer_token_refresh_cb], :void

    callback :socket_cb, [:int, :int, :int, :pointer], :int
    attach_function :rd_kafka_conf_set_socket_cb, [Config, :socket_cb], :void

    # @todo first :pointer is to struct sockaddr
    callback :connect_cb, [:int, :pointer, :int, :string, :pointer], :int
    attach_function :rd_kafka_conf_set_connect_cb, [Config, :connect_cb], :void

    callback :closesocket_cb, [:int, :pointer], :int
    attach_function :rd_kafka_conf_set_closesocket_cb, [Config, :closesocket_cb], :void

    # @test
    if !::FFI::Platform.windows?
      callback :open_cb, [:string, :int, :mode_t, :pointer], :int
      attach_function :rd_kafka_conf_set_open_cb, [Config, :open_cb], :void
    end

    # @test
    callback :ssl_cert_verify_cb, [Client, :string, :int32, :pointer, :int, :string, :size_t, :string, :size_t, :pointer], :int
    attach_function :rd_kafka_conf_set_ssl_cert_verify_cb, [Config, :ssl_cert_verify_cb], :config_result

    attach_function :rd_kafka_conf_set_ssl_cert, [Config, :cert_type, :cert_enc, :buffer_in, :size_t, :pointer, :size_t], :config_result
    # :rd_kafka_conf_set_opaque

    # NOTE: Never call rd_kafka_conf_destroy on a Config that has been passed
    #   to rd_kafka_new as librdkafka takes ownership at that point.
    attach_function :rd_kafka_conf_destroy, [Config], :void

    # Topic Config

    attach_function :rd_kafka_topic_conf_new, [], TopicConfig
    attach_function :rd_kafka_topic_conf_set, [TopicConfig, :string, :string, :pointer, :size_t], :config_result
    attach_function :rd_kafka_topic_conf_get, [TopicConfig, :string, :pointer, :pointer], :config_result
    attach_function :rd_kafka_topic_conf_dup, [TopicConfig], TopicConfig

    callback :topic_partitioner_cb, [Topic, :string, :size_t, :int32, :pointer, :pointer], :int32
    attach_function :rd_kafka_topic_conf_set_partitioner_cb, [TopicConfig, :topic_partitioner_cb], :void

    attach_function :rd_kafka_topic_conf_destroy, [TopicConfig], :void

    # Message

    attach_function :rd_kafka_message_timestamp, [Message.by_ref, :pointer], :int64
    attach_function :rd_kafka_message_latency, [Message.by_ref], :int64
    attach_function :rd_kafka_message_status, [Message.by_ref], :message_status
    attach_function :rd_kafka_message_headers, [Message.by_ref, Message::Header], :error_code
    attach_function :rd_kafka_message_detach_headers, [Message.by_ref, Message::Header], :error_code
    attach_function :rd_kafka_message_set_headers, [Message.by_ref, Message::Header], :void
    attach_function :rd_kafka_message_destroy, [Message.by_ref], :void

    # Message::Header
    attach_function :rd_kafka_headers_new, [:size_t], Message::Header
    attach_function :rd_kafka_headers_copy, [Message::Header], Message::Header
    attach_function :rd_kafka_header_cnt, [Message::Header], :size_t
    attach_function :rd_kafka_header_add, [Message::Header, :string, :size_t, :string, :size_t], :error_code
    attach_function :rd_kafka_header_remove, [Message::Header, :string], :error_code
    attach_function :rd_kafka_header_get, [Message::Header, :size_t, :string, :pointer, :pointer], :error_code
    attach_function :rd_kafka_header_get_all, [Message::Header, :size_t, :pointer, :pointer, :pointer], :error_code
    attach_function :rd_kafka_header_get_last, [Message::Header, :string, :pointer, :pointer], :error_code
    attach_function :rd_kafka_headers_destroy, [Message::Header], :void

    # Consumer

    ## High Level Consumer API
    attach_function :rd_kafka_subscribe, [Consumer, TopicPartitionList.by_ref], :error_code
    attach_function :rd_kafka_unsubscribe, [Consumer], :error_code
    attach_function :rd_kafka_subscription, [Consumer, :pointer], :error_code
    attach_function :rd_kafka_consumer_poll, [Consumer, :timeout_ms], Message.by_ref, blocking: true
    attach_function :rd_kafka_poll_set_consumer, [Consumer], :error_code
    attach_function :rd_kafka_consumer_close, [Consumer], :error_code, blocking: true

    attach_function :rd_kafka_assign, [Consumer, TopicPartitionList.by_ref], :error_code
    attach_function :rd_kafka_assignment, [Consumer, :pointer], :error_code
    attach_function :rd_kafka_commit, [Consumer, TopicPartitionList.by_ref, :bool], :error_code, blocking: true
    # @test
    attach_function :rd_kafka_commit_message, [Consumer, Message.by_ref, :bool], :error_code, blocking: true

    # @todo?
    # attach_function :rd_kafka_commit_queue, [Consumer], TopicPartitionList.by_ref, Queue, :commit_queue_cb, :pointer], :error_code

    attach_function :rd_kafka_committed, [Consumer, TopicPartitionList.by_ref, :timeout_ms], :error_code, blocking: true

    # @todo
    # attach_function :rd_kafka_position, [Consumer, TopicPartitionList.by_ref], :error_code

    # Producer
    # @todo

    # Queue

    attach_function :rd_kafka_queue_new, [Client], Queue
    attach_function :rd_kafka_queue_poll, [Queue, :timeout_ms], Event
    attach_function :rd_kafka_queue_get_main, [Client], Queue
    attach_function :rd_kafka_queue_get_consumer, [Consumer], Queue
    attach_function :rd_kafka_queue_get_partition, [Consumer, :topic, :partition], Queue
    attach_function :rd_kafka_queue_get_background, [Client], Queue
    attach_function :rd_kafka_queue_forward, [Queue, Queue], :void
    attach_function :rd_kafka_set_log_queue, [Client, Queue], :error_code
    attach_function :rd_kafka_queue_length, [Queue], :size_t
    # :rd_kafka_queue_io_event_enable
    # :rd_kafka_queue_cb_event_enable
    attach_function :rd_kafka_queue_destroy, [Queue], :void

    # Event

    attach_function :rd_kafka_event_type, [Event], :event_type
    attach_function :rd_kafka_event_name, [Event], :string

    attach_function :rd_kafka_event_message_next, [Event], Message.by_ref
    attach_function :rd_kafka_event_message_array, [Event, :pointer, :size_t], :size_t
    attach_function :rd_kafka_event_message_count, [Event], :size_t
    attach_function :rd_kafka_event_config_string, [Event], :string
    attach_function :rd_kafka_event_error, [Event], :error_code
    attach_function :rd_kafka_event_error_string, [Event], :string
    attach_function :rd_kafka_event_error_is_fatal, [Event], :bool
    # :rd_kafka_event_opaque
    attach_function :rd_kafka_event_log, [Event, :pointer, :pointer, :pointer], :int
    attach_function :rd_kafka_event_stats, [Event], :string
    attach_function :rd_kafka_event_topic_partition_list, [Event], TopicPartitionList.by_ref
    attach_function :rd_kafka_event_topic_partition, [Event], TopicPartition.by_ref
    attach_function :rd_kafka_event_destroy, [Event], :void

    # Topics

    attach_function :rd_kafka_topic_new, [Client, :string, TopicConfig], Topic
    attach_function :rd_kafka_topic_name, [Topic], :string
    attach_function :rd_kafka_seek, [Topic, :partition, :offset, :timeout_ms], :error_code, blocking: true

    # @note May only be called inside a topic_partitioner_cb
    attach_function :rd_kafka_topic_partition_available, [Topic, :partition], :bool

    # @todo?
    # attach_function :rd_kafka_topic_opaque, [Topic], :pointer
    # @todo
    attach_function :rd_kafka_topic_destroy, [Topic], :void

    # Topic Partition

    # NOTE: Must never by called for elements in a TopicPartitionList. Mostly
    #   here for completeness since it likely never makes sense to call.
    attach_function :rd_kafka_topic_partition_destroy, [TopicPartition.by_ref], :void

    # Topic Partition List
    attach_function :rd_kafka_topic_partition_list_new, [:int32], TopicPartitionList.by_ref
    attach_function :rd_kafka_topic_partition_list_add, [TopicPartitionList.by_ref, :string, :int32], TopicPartition.by_ref
    attach_function :rd_kafka_topic_partition_list_add_range, [TopicPartitionList.by_ref, :string, :int32, :int32], :void
    attach_function :rd_kafka_topic_partition_list_del, [TopicPartitionList.by_ref, :string, :int32], :int
    attach_function :rd_kafka_topic_partition_list_del_by_idx, [TopicPartitionList.by_ref, :int], :int
    attach_function :rd_kafka_topic_partition_list_copy, [TopicPartitionList.by_ref], TopicPartitionList.by_ref
    attach_function :rd_kafka_topic_partition_list_set_offset, [TopicPartitionList.by_ref, :string, :partition, :offset], :error_code
    attach_function :rd_kafka_topic_partition_list_find, [TopicPartitionList.by_ref, :string, :int32], TopicPartition.by_ref

    callback :topic_list_cmp_func, [TopicPartition.by_ref, TopicPartition.by_ref, :pointer], :int
    attach_function :rd_kafka_topic_partition_list_sort, [TopicPartitionList.by_ref, :topic_list_cmp_func, :pointer ], :void

    attach_function :rd_kafka_topic_partition_list_destroy, [TopicPartitionList.by_ref], :void

    # Admin Commands

    ## Create Topics / NewTopic

    attach_function :rd_kafka_CreateTopics, [Client, :pointer, :size_t, :pointer, Queue], :void
    attach_function :rd_kafka_CreateTopics_result_topics, [Event, :pointer], :pointer
    attach_function :rd_kafka_NewTopic_new, [:topic, :int, :int, :pointer, :size_t], Admin::NewTopic
    attach_function :rd_kafka_NewTopic_set_replica_assignment, [Admin::NewTopic, :partition, :pointer, :size_t, :pointer, :size_t], :error_code
    attach_function :rd_kafka_NewTopic_set_config, [Admin::NewTopic, :string, :string], :error_code
    attach_function :rd_kafka_NewTopic_destroy, [Admin::NewTopic], :void
    # :rd_kafka_NewTopic_destroy_array

    # DeleteTopics / DeleteTopic

    attach_function :rd_kafka_DeleteTopics, [Client, :pointer, :size_t, :pointer, Queue], :void
    attach_function :rd_kafka_DeleteTopics_result_topics, [Event, :pointer], :pointer
    attach_function :rd_kafka_DeleteTopic_new, [:string], Admin::DeleteTopic
    attach_function :rd_kafka_DeleteTopic_destroy, [Admin::DeleteTopic], :void
    # :rd_kafka_DeleteTopic_destroy_array
  end
end
