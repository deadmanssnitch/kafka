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

    # Returns the loaded version of librdkafka
    #
    # @return [String] Version string
    def self.version
      rd_kafka_version_str
    end

    # Returns the set of features available from librdkafka
    #
    # @return [Array<String>] List of available features
    def self.features
      conf = Config.new
      conf.get("builtin.features").split(",")
    ensure
      conf.destroy
    end

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
    RD_KAFKA_RESP_ERR__BEGIN = -200
    RD_KAFKA_RESP_ERR__BAD_MSG = -199
    RD_KAFKA_RESP_ERR__BAD_COMPRESSION = -198
    RD_KAFKA_RESP_ERR__DESTROY = -197
    RD_KAFKA_RESP_ERR__FAIL = -196
    RD_KAFKA_RESP_ERR__TRANSPORT = -195
    RD_KAFKA_RESP_ERR__CRIT_SYS_RESOURCE = -194
    RD_KAFKA_RESP_ERR__RESOLVE = -193
    RD_KAFKA_RESP_ERR__MSG_TIMED_OUT = -192
    RD_KAFKA_RESP_ERR__PARTITION_EOF = -191
    RD_KAFKA_RESP_ERR__UNKNOWN_PARTITION = -190
    RD_KAFKA_RESP_ERR__FS = -189
    RD_KAFKA_RESP_ERR__UNKNOWN_TOPIC = -188
    RD_KAFKA_RESP_ERR__ALL_BROKERS_DOWN = -187
    RD_KAFKA_RESP_ERR__INVALID_ARG = -186
    RD_KAFKA_RESP_ERR__TIMED_OUT = -185
    RD_KAFKA_RESP_ERR__QUEUE_FULL = -184
    RD_KAFKA_RESP_ERR__ISR_INSUFF = -183
    RD_KAFKA_RESP_ERR__NODE_UPDATE = -182
    RD_KAFKA_RESP_ERR__SSL = -181
    RD_KAFKA_RESP_ERR__WAIT_COORD = -180
    RD_KAFKA_RESP_ERR__UNKNOWN_GROUP = -179
    RD_KAFKA_RESP_ERR__IN_PROGRESS = -178
    RD_KAFKA_RESP_ERR__PREV_IN_PROGRESS = -177
    RD_KAFKA_RESP_ERR__EXISTING_SUBSCRIPTION = -176
    RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS = -175
    RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS = -174
    RD_KAFKA_RESP_ERR__CONFLICT = -173
    RD_KAFKA_RESP_ERR__STATE = -172
    RD_KAFKA_RESP_ERR__UNKNOWN_PROTOCOL = -171
    RD_KAFKA_RESP_ERR__NOT_IMPLEMENTED = -170
    RD_KAFKA_RESP_ERR__AUTHENTICATION = -169
    RD_KAFKA_RESP_ERR__NO_OFFSET = -168
    RD_KAFKA_RESP_ERR__OUTDATED = -167
    RD_KAFKA_RESP_ERR__TIMED_OUT_QUEUE = -166
    RD_KAFKA_RESP_ERR__UNSUPPORTED_FEATURE = -165
    RD_KAFKA_RESP_ERR__WAIT_CACHE = -164
    RD_KAFKA_RESP_ERR__INTR = -163
    RD_KAFKA_RESP_ERR__KEY_SERIALIZATION = -162
    RD_KAFKA_RESP_ERR__VALUE_SERIALIZATION = -161
    RD_KAFKA_RESP_ERR__KEY_DESERIALIZATION = -160
    RD_KAFKA_RESP_ERR__VALUE_DESERIALIZATION = -159
    RD_KAFKA_RESP_ERR__PARTIAL = -158
    RD_KAFKA_RESP_ERR__READ_ONLY = -157
    RD_KAFKA_RESP_ERR__NOENT = -156
    RD_KAFKA_RESP_ERR__UNDERFLOW = -155
    RD_KAFKA_RESP_ERR__INVALID_TYPE = -154
    RD_KAFKA_RESP_ERR__RETRY = -153
    RD_KAFKA_RESP_ERR__PURGE_QUEUE = -152
    RD_KAFKA_RESP_ERR__PURGE_INFLIGHT = -151
    RD_KAFKA_RESP_ERR__FATAL = -150
    RD_KAFKA_RESP_ERR__INCONSISTENT = -149
    RD_KAFKA_RESP_ERR__GAPLESS_GUARANTEE = -148
    RD_KAFKA_RESP_ERR__MAX_POLL_EXCEEDED = -147
    RD_KAFKA_RESP_ERR__UNKNOWN_BROKER = -146
    RD_KAFKA_RESP_ERR__NOT_CONFIGURED = -145
    RD_KAFKA_RESP_ERR__FENCED = -144
    RD_KAFKA_RESP_ERR__APPLICATION = -143
    RD_KAFKA_RESP_ERR__END = -100
    RD_KAFKA_RESP_ERR_UNKNOWN = -1
    RD_KAFKA_RESP_ERR_NO_ERROR = 0
    RD_KAFKA_RESP_ERR_OFFSET_OUT_OF_RANGE = 1
    RD_KAFKA_RESP_ERR_INVALID_MSG = 2
    RD_KAFKA_RESP_ERR_UNKNOWN_TOPIC_OR_PART = 3
    RD_KAFKA_RESP_ERR_INVALID_MSG_SIZE = 4
    RD_KAFKA_RESP_ERR_LEADER_NOT_AVAILABLE = 5
    RD_KAFKA_RESP_ERR_NOT_LEADER_FOR_PARTITION = 6
    RD_KAFKA_RESP_ERR_REQUEST_TIMED_OUT = 7
    RD_KAFKA_RESP_ERR_BROKER_NOT_AVAILABLE = 8
    RD_KAFKA_RESP_ERR_REPLICA_NOT_AVAILABLE = 9
    RD_KAFKA_RESP_ERR_MSG_SIZE_TOO_LARGE = 10
    RD_KAFKA_RESP_ERR_STALE_CTRL_EPOCH = 11
    RD_KAFKA_RESP_ERR_OFFSET_METADATA_TOO_LARGE = 12
    RD_KAFKA_RESP_ERR_NETWORK_EXCEPTION = 13
    RD_KAFKA_RESP_ERR_COORDINATOR_LOAD_IN_PROGRESS = 14
    RD_KAFKA_RESP_ERR_COORDINATOR_NOT_AVAILABLE = 15
    RD_KAFKA_RESP_ERR_NOT_COORDINATOR = 16
    RD_KAFKA_RESP_ERR_TOPIC_EXCEPTION = 17
    RD_KAFKA_RESP_ERR_RECORD_LIST_TOO_LARGE = 18
    RD_KAFKA_RESP_ERR_NOT_ENOUGH_REPLICAS = 19
    RD_KAFKA_RESP_ERR_NOT_ENOUGH_REPLICAS_AFTER_APPEND = 20
    RD_KAFKA_RESP_ERR_INVALID_REQUIRED_ACKS = 21
    RD_KAFKA_RESP_ERR_ILLEGAL_GENERATION = 22
    RD_KAFKA_RESP_ERR_INCONSISTENT_GROUP_PROTOCOL = 23
    RD_KAFKA_RESP_ERR_INVALID_GROUP_ID = 24
    RD_KAFKA_RESP_ERR_UNKNOWN_MEMBER_ID = 25
    RD_KAFKA_RESP_ERR_INVALID_SESSION_TIMEOUT = 26
    RD_KAFKA_RESP_ERR_REBALANCE_IN_PROGRESS = 27
    RD_KAFKA_RESP_ERR_INVALID_COMMIT_OFFSET_SIZE = 28
    RD_KAFKA_RESP_ERR_TOPIC_AUTHORIZATION_FAILED = 29
    RD_KAFKA_RESP_ERR_GROUP_AUTHORIZATION_FAILED = 30
    RD_KAFKA_RESP_ERR_CLUSTER_AUTHORIZATION_FAILED = 31
    RD_KAFKA_RESP_ERR_INVALID_TIMESTAMP = 32
    RD_KAFKA_RESP_ERR_UNSUPPORTED_SASL_MECHANISM = 33
    RD_KAFKA_RESP_ERR_ILLEGAL_SASL_STATE = 34
    RD_KAFKA_RESP_ERR_UNSUPPORTED_VERSION = 35
    RD_KAFKA_RESP_ERR_TOPIC_ALREADY_EXISTS = 36
    RD_KAFKA_RESP_ERR_INVALID_PARTITIONS = 37
    RD_KAFKA_RESP_ERR_INVALID_REPLICATION_FACTOR = 38
    RD_KAFKA_RESP_ERR_INVALID_REPLICA_ASSIGNMENT = 39
    RD_KAFKA_RESP_ERR_INVALID_CONFIG = 40
    RD_KAFKA_RESP_ERR_NOT_CONTROLLER = 41
    RD_KAFKA_RESP_ERR_INVALID_REQUEST = 42
    RD_KAFKA_RESP_ERR_UNSUPPORTED_FOR_MESSAGE_FORMAT = 43
    RD_KAFKA_RESP_ERR_POLICY_VIOLATION = 44
    RD_KAFKA_RESP_ERR_OUT_OF_ORDER_SEQUENCE_NUMBER = 45
    RD_KAFKA_RESP_ERR_DUPLICATE_SEQUENCE_NUMBER = 46
    RD_KAFKA_RESP_ERR_INVALID_PRODUCER_EPOCH = 47
    RD_KAFKA_RESP_ERR_INVALID_TXN_STATE = 48
    RD_KAFKA_RESP_ERR_INVALID_PRODUCER_ID_MAPPING = 49
    RD_KAFKA_RESP_ERR_INVALID_TRANSACTION_TIMEOUT = 50
    RD_KAFKA_RESP_ERR_CONCURRENT_TRANSACTIONS = 51
    RD_KAFKA_RESP_ERR_TRANSACTION_COORDINATOR_FENCED = 52
    RD_KAFKA_RESP_ERR_TRANSACTIONAL_ID_AUTHORIZATION_FAILED = 53
    RD_KAFKA_RESP_ERR_SECURITY_DISABLED = 54
    RD_KAFKA_RESP_ERR_OPERATION_NOT_ATTEMPTED = 55
    RD_KAFKA_RESP_ERR_KAFKA_STORAGE_ERROR = 56
    RD_KAFKA_RESP_ERR_LOG_DIR_NOT_FOUND = 57
    RD_KAFKA_RESP_ERR_SASL_AUTHENTICATION_FAILED = 58
    RD_KAFKA_RESP_ERR_UNKNOWN_PRODUCER_ID = 59
    RD_KAFKA_RESP_ERR_REASSIGNMENT_IN_PROGRESS = 60
    RD_KAFKA_RESP_ERR_DELEGATION_TOKEN_AUTH_DISABLED = 61
    RD_KAFKA_RESP_ERR_DELEGATION_TOKEN_NOT_FOUND = 62
    RD_KAFKA_RESP_ERR_DELEGATION_TOKEN_OWNER_MISMATCH = 63
    RD_KAFKA_RESP_ERR_DELEGATION_TOKEN_REQUEST_NOT_ALLOWED = 64
    RD_KAFKA_RESP_ERR_DELEGATION_TOKEN_AUTHORIZATION_FAILED = 65
    RD_KAFKA_RESP_ERR_DELEGATION_TOKEN_EXPIRED = 66
    RD_KAFKA_RESP_ERR_INVALID_PRINCIPAL_TYPE = 67
    RD_KAFKA_RESP_ERR_NON_EMPTY_GROUP = 68
    RD_KAFKA_RESP_ERR_GROUP_ID_NOT_FOUND = 69
    RD_KAFKA_RESP_ERR_FETCH_SESSION_ID_NOT_FOUND = 70
    RD_KAFKA_RESP_ERR_INVALID_FETCH_SESSION_EPOCH = 71
    RD_KAFKA_RESP_ERR_LISTENER_NOT_FOUND = 72
    RD_KAFKA_RESP_ERR_TOPIC_DELETION_DISABLED = 73
    RD_KAFKA_RESP_ERR_FENCED_LEADER_EPOCH = 74
    RD_KAFKA_RESP_ERR_UNKNOWN_LEADER_EPOCH = 75
    RD_KAFKA_RESP_ERR_UNSUPPORTED_COMPRESSION_TYPE = 76
    RD_KAFKA_RESP_ERR_STALE_BROKER_EPOCH = 77
    RD_KAFKA_RESP_ERR_OFFSET_NOT_AVAILABLE = 78
    RD_KAFKA_RESP_ERR_MEMBER_ID_REQUIRED = 79
    RD_KAFKA_RESP_ERR_PREFERRED_LEADER_NOT_AVAILABLE = 80
    RD_KAFKA_RESP_ERR_GROUP_MAX_SIZE_REACHED = 81
    RD_KAFKA_RESP_ERR_FENCED_INSTANCE_ID = 82

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

    # Flags for rd_kafka_produce, rd_kafka_producev, and
    # rd_kafka_produce_batch.
    #
    # @see rdkafka.h
    RD_KAFKA_MSG_F_FREE      = 0x01
    RD_KAFKA_MSG_F_COPY      = 0x02
    RD_KAFKA_MSG_F_BLOCK     = 0x04
    RD_KAFKA_MSG_F_PARTITION = 0x04

    # Flags for rd_kafka_purge
    #
    # @see rdkafka.h
    RD_KAFKA_PURGE_F_QUEUE        = 0x01
    RD_KAFKA_PURGE_F_INFLIGHT     = 0x02
    RD_KAFKA_PURGE_F_NON_BLOCKING = 0x04

    # rd_kafka_producev va-arg vtype constants.
    RD_KAFKA_VTYPE_END       = 0
    RD_KAFKA_VTYPE_TOPIC     = 1
    RD_KAFKA_VTYPE_RKT       = 2
    RD_KAFKA_VTYPE_PARTITION = 3
    RD_KAFKA_VTYPE_VALUE     = 4
    RD_KAFKA_VTYPE_KEY       = 5
    RD_KAFKA_VTYPE_OPAQUE    = 6
    RD_KAFKA_VTYPE_MSGFLAGS  = 7
    RD_KAFKA_VTYPE_TIMESTAMP = 8
    RD_KAFKA_VTYPE_HEADER    = 9
    RD_KAFKA_VTYPE_HEADERS   = 10

    # Use for partition when it should be assigned by the configured
    # partitioner.
    RD_KAFKA_PARTITION_UA = -1

    # Enum of va-arg vtypes for calling rd_kafka_producev
    #
    # @see rdkafka.h rd_kafka_producev
    enum :vtype, [
      :end,       RD_KAFKA_VTYPE_END,
      :topic,     RD_KAFKA_VTYPE_TOPIC,
      :rkt,       RD_KAFKA_VTYPE_RKT,
      :partition, RD_KAFKA_VTYPE_PARTITION,
      :value,     RD_KAFKA_VTYPE_VALUE,
      :key,       RD_KAFKA_VTYPE_KEY,
      :opaque,    RD_KAFKA_VTYPE_OPAQUE,
      :msgflags,  RD_KAFKA_VTYPE_MSGFLAGS,
      :timestamp, RD_KAFKA_VTYPE_TIMESTAMP,
      :header,    RD_KAFKA_VTYPE_HEADER,
      :headers,   RD_KAFKA_VTYPE_HEADERS,
    ]

    RD_KAFKA_ADMIN_OP_ANY              = 0
    RD_KAFKA_ADMIN_OP_CREATETOPICS     = 1
    RD_KAFKA_ADMIN_OP_DELETETOPICS     = 2
    RD_KAFKA_ADMIN_OP_CREATEPARTITIONS = 3
    RD_KAFKA_ADMIN_OP_ALTERCONFIGS     = 4
    RD_KAFKA_ADMIN_OP_DESCRIBECONFIGS  = 5

    enum :admin_operation, [
      :any,               RD_KAFKA_ADMIN_OP_ANY,
      :create_topics,     RD_KAFKA_ADMIN_OP_CREATETOPICS,
      :delete_topics,     RD_KAFKA_ADMIN_OP_DELETETOPICS,
      :create_partitions, RD_KAFKA_ADMIN_OP_CREATEPARTITIONS,
      :alter_configs,     RD_KAFKA_ADMIN_OP_ALTERCONFIGS,
      :describe_configs,  RD_KAFKA_ADMIN_OP_DESCRIBECONFIGS,
    ]

    RD_KAFKA_RESOURCE_UNKNOWN = 0
    RD_KAFKA_RESOURCE_ANY     = 1
    RD_KAFKA_RESOURCE_TOPIC   = 2
    RD_KAFKA_RESOURCE_GROUP   = 3
    RD_KAFKA_RESOURCE_BROKER  = 4

    enum :resource_type, [
      :unknown, RD_KAFKA_RESOURCE_UNKNOWN,
      :any,     RD_KAFKA_RESOURCE_ANY,
      :topic,   RD_KAFKA_RESOURCE_TOPIC,
      :group,   RD_KAFKA_RESOURCE_GROUP,
      :broker,  RD_KAFKA_RESOURCE_BROKER,
    ]

    RD_KAFKA_CONFIG_SOURCE_UNKNOWN_CONFIG                = 0
    RD_KAFKA_CONFIG_SOURCE_DYNAMIC_TOPIC_CONFIG          = 1
    RD_KAFKA_CONFIG_SOURCE_DYNAMIC_BROKER_CONFIG         = 2
    RD_KAFKA_CONFIG_SOURCE_DYNAMIC_DEFAULT_BROKER_CONFIG = 3
    RD_KAFKA_CONFIG_SOURCE_STATIC_BROKER_CONFIG          = 4
    RD_KAFKA_CONFIG_SOURCE_DEFAULT_CONFIG                = 5

    enum :config_source, [
      :unknown_config,                RD_KAFKA_CONFIG_SOURCE_UNKNOWN_CONFIG,
      :dynamic_topic_config,          RD_KAFKA_CONFIG_SOURCE_DYNAMIC_TOPIC_CONFIG,
      :dynamic_broker_config,         RD_KAFKA_CONFIG_SOURCE_DYNAMIC_BROKER_CONFIG,
      :dynamic_default_broker_config, RD_KAFKA_CONFIG_SOURCE_DYNAMIC_DEFAULT_BROKER_CONFIG,
      :static_broker_config,          RD_KAFKA_CONFIG_SOURCE_STATIC_BROKER_CONFIG,
      :default_config,                RD_KAFKA_CONFIG_SOURCE_DEFAULT_CONFIG,
    ]

    typedef :int,     :timeout_ms
    typedef :int32,   :partition
    typedef :int32,   :broker_id
    typedef :int64,   :offset
    typedef :string,  :topic
    typedef :pointer, :opaque

    # Load types after enums and constants so they're able to reference them.
    require "kafka/ffi/admin"
    require "kafka/ffi/error"
    require "kafka/ffi/event"
    require "kafka/ffi/queue"
    require "kafka/ffi/topic"
    require "kafka/ffi/opaque"
    require "kafka/ffi/client"
    require "kafka/ffi/consumer"
    require "kafka/ffi/producer"
    require "kafka/ffi/config"
    require "kafka/ffi/message"
    require "kafka/ffi/metadata"
    require "kafka/ffi/group_list"
    require "kafka/ffi/group_info"
    require "kafka/ffi/group_member_info"
    require "kafka/ffi/topic_config"
    require "kafka/ffi/opaque_pointer"
    require "kafka/ffi/topic_partition"
    require "kafka/ffi/topic_partition_list"
    require "kafka/ffi/topic_metadata"
    require "kafka/ffi/broker_metadata"
    require "kafka/ffi/partition_metadata"

    # Errors
    attach_function :rd_kafka_err2str, [:error_code], :string
    attach_function :rd_kafka_err2name, [:error_code], :string
    attach_function :rd_kafka_last_error, [], :error_code

    # Version
    attach_function :rd_kafka_version, [], :int
    attach_function :rd_kafka_version_str, [], :string

    # Client
    attach_function :rd_kafka_new, [:kafka_type, Config, :pointer, :int], Client, blocking: true
    attach_function :rd_kafka_type, [Client], :kafka_type
    attach_function :rd_kafka_name, [Client], :string
    attach_function :rd_kafka_memberid, [Client], :pointer
    attach_function :rd_kafka_clusterid, [Client, :timeout_ms], :pointer, blocking: true
    attach_function :rd_kafka_controllerid, [Client, :timeout_ms], :broker_id, blocking: true
    attach_function :rd_kafka_default_topic_conf_dup, [Client], TopicConfig
    attach_function :rd_kafka_conf, [Client], Config
    attach_function :rd_kafka_poll, [Client, :timeout_ms], :int, blocking: true
    attach_function :rd_kafka_outq_len, [Client], :int
    attach_function :rd_kafka_brokers_add, [Client, :string], :int

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
    attach_function :rd_kafka_query_watermark_offsets, [Client, :topic, :partition, :pointer, :pointer, :timeout_ms], :error_code, blocking: true
    # @test
    attach_function :rd_kafka_get_watermark_offsets, [Client, :topic, :partition, :pointer, :pointer], :error_code
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

    callback :rebalance_cb, [Client, :error_code, TopicPartitionList.by_ref, Opaque], :void
    attach_function :rd_kafka_conf_set_rebalance_cb, [Config, :rebalance_cb], :void

    callback :offset_commit_cb, [Client, :error_code, TopicPartitionList.by_ref, :pointer], :void
    attach_function :rd_kafka_conf_set_offset_commit_cb, [Config, :offset_commit_cb], :void

    callback :error_cb, [Client, :error_code, :string, :pointer], :void
    attach_function :rd_kafka_conf_set_error_cb, [Config, :error_cb], :void

    callback :throttle_cb, [Client, :string, :broker_id, :int, :pointer], :void
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
    callback :ssl_cert_verify_cb, [Client, :string, :broker_id, :pointer, :int, :string, :size_t, :string, :size_t, :pointer], :int
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

    callback :topic_partitioner_cb, [Topic, :string, :size_t, :int32, :pointer, :pointer], :partition
    attach_function :rd_kafka_topic_conf_set_partitioner_cb, [TopicConfig, :topic_partitioner_cb], :void

    attach_function :rd_kafka_topic_conf_destroy, [TopicConfig], :void

    # Message
    attach_function :rd_kafka_message_timestamp, [Message.by_ref, :pointer], :int64
    attach_function :rd_kafka_message_latency, [Message.by_ref], :int64
    attach_function :rd_kafka_message_status, [Message.by_ref], :message_status
    attach_function :rd_kafka_message_broker_id, [Message.by_ref], :broker_id
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

    ## Legacy Simple Consumer API
    attach_function :rd_kafka_consume_start, [Topic, :partition, :offset], :int
    attach_function :rd_kafka_consume_start_queue, [Topic, :partition, :offset, Queue], :int
    attach_function :rd_kafka_consume_stop, [Topic, :partition], :int
    attach_function :rd_kafka_consume, [Topic, :partition, :timeout_ms], Message.by_ref, blocking: true
    attach_function :rd_kafka_consume_batch, [Topic, :partition, :timeout_ms, :pointer, :size_t], :ssize_t, blocking: true
    attach_function :rd_kafka_consume_callback, [Topic, :partition, :timeout_ms, :consume_cb, :pointer], :int, blocking: true

    ### Simple Consumer Queue API
    attach_function :rd_kafka_consume_queue, [Queue, :timeout_ms], Message.by_ref, blocking: true
    attach_function :rd_kafka_consume_batch_queue, [Queue, :timeout_ms, :pointer, :size_t], :ssize_t, blocking: true
    attach_function :rd_kafka_consume_callback_queue, [Queue, :timeout_ms, :consume_cb, :pointer], :int, blocking: true

    ### Simple Consumer Topic + Partition API
    attach_function :rd_kafka_offset_store, [Topic, :partition, :offset], :error_code
    attach_function :rd_kafka_offsets_store, [Client, TopicPartitionList.by_ref], :error_code

    # Producer
    attach_function :rd_kafka_produce, [Topic, :partition, :int, :pointer, :size_t, :string, :size_t, :pointer], :int
    attach_function :rd_kafka_producev, [Producer, :varargs], :error_code
    attach_function :rd_kafka_produce_batch, [Topic, :partition, :int, Message.by_ref, :int], :int
    attach_function :rd_kafka_flush, [Producer, :timeout_ms], :error_code, blocking: true
    attach_function :rd_kafka_purge, [Producer, :int], :error_code, blocking: true

    ## Partitioners

    attach_function :rd_kafka_msg_partitioner_random, [Topic, :string, :size_t, :int32, Opaque, Opaque], :partition
    attach_function :rd_kafka_msg_partitioner_consistent, [Topic, :string, :size_t, :int32, Opaque, Opaque], :partition
    attach_function :rd_kafka_msg_partitioner_consistent_random, [Topic, :string, :size_t, :int32, Opaque, Opaque], :partition
    attach_function :rd_kafka_msg_partitioner_murmur2, [Topic, :string, :size_t, :int32, Opaque, Opaque], :partition
    attach_function :rd_kafka_msg_partitioner_murmur2_random, [Topic, :string, :size_t, :int32, Opaque, Opaque], :partition
    attach_function :rd_kafka_msg_partitioner_fnv1a, [Topic, :string, :size_t, :int32, Opaque, Opaque], :partition
    attach_function :rd_kafka_msg_partitioner_fnv1a_random, [Topic, :string, :size_t, :int32, Opaque, Opaque], :partition

    # Metadata
    attach_function :rd_kafka_metadata, [Client, :bool, Topic, :pointer, :timeout_ms], :error_code, blocking: true
    attach_function :rd_kafka_metadata_destroy, [Metadata.by_ref], :void

    # Group List
    attach_function :rd_kafka_list_groups, [Client, :string, :pointer, :timeout_ms], :error_code, blocking: true
    attach_function :rd_kafka_group_list_destroy, [GroupList.by_ref], :void

    # Queue
    attach_function :rd_kafka_queue_new, [Client], Queue
    attach_function :rd_kafka_queue_poll, [Queue, :timeout_ms], Event, blocking: true
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

    # Event casting
    #   Each of these functions will type check the Event to see if it is the
    #   desired type, returning nil if it is not.
    attach_function :rd_kafka_event_CreateTopics_result, [Event], Event
    attach_function :rd_kafka_event_DeleteTopics_result, [Event], Event
    attach_function :rd_kafka_event_CreatePartitions_result, [Event], Event
    attach_function :rd_kafka_event_AlterConfigs_result, [Event], Event
    attach_function :rd_kafka_event_DescribeConfigs_result, [Event], Event

    # Topics
    attach_function :rd_kafka_topic_new, [Client, :topic, TopicConfig], Topic
    attach_function :rd_kafka_topic_name, [Topic], :topic
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
    attach_function :rd_kafka_topic_partition_list_add, [TopicPartitionList.by_ref, :topic, :partition], TopicPartition.by_ref
    attach_function :rd_kafka_topic_partition_list_add_range, [TopicPartitionList.by_ref, :topic, :int32, :int32], :void
    attach_function :rd_kafka_topic_partition_list_del, [TopicPartitionList.by_ref, :topic, :partition], :int
    attach_function :rd_kafka_topic_partition_list_del_by_idx, [TopicPartitionList.by_ref, :int], :int
    attach_function :rd_kafka_topic_partition_list_copy, [TopicPartitionList.by_ref], TopicPartitionList.by_ref
    attach_function :rd_kafka_topic_partition_list_set_offset, [TopicPartitionList.by_ref, :topic, :partition, :offset], :error_code
    attach_function :rd_kafka_topic_partition_list_find, [TopicPartitionList.by_ref, :topic, :partition], TopicPartition.by_ref

    callback :topic_list_cmp_func, [TopicPartition.by_ref, TopicPartition.by_ref, :pointer], :int
    attach_function :rd_kafka_topic_partition_list_sort, [TopicPartitionList.by_ref, :topic_list_cmp_func, :pointer ], :void

    attach_function :rd_kafka_topic_partition_list_destroy, [TopicPartitionList.by_ref], :void

    # Admin Commands

    ## AdminOptions
    attach_function :rd_kafka_AdminOptions_new, [Client, :admin_operation], Admin::AdminOptions
    attach_function :rd_kafka_AdminOptions_set_request_timeout, [Admin::AdminOptions, :timeout_ms, :pointer, :size_t], :error_code
    attach_function :rd_kafka_AdminOptions_set_operation_timeout, [Admin::AdminOptions, :timeout_ms, :pointer, :size_t], :error_code
    attach_function :rd_kafka_AdminOptions_set_validate_only, [Admin::AdminOptions, :bool, :pointer, :size_t], :error_code
    attach_function :rd_kafka_AdminOptions_set_broker, [Admin::AdminOptions, :broker_id, :pointer, :size_t], :error_code
    # :rd_kafka_AdminOptions_set_opaque
    attach_function :rd_kafka_AdminOptions_destroy, [Admin::AdminOptions], :void

    ## DescribeConfigs
    attach_function :rd_kafka_DescribeConfigs, [Client, :pointer, :size_t, Admin::AdminOptions, Queue], :void
    attach_function :rd_kafka_DescribeConfigs_result_resources, [Event, :pointer], :pointer

    ## AlterConfigs
    attach_function :rd_kafka_AlterConfigs, [Client, :pointer, :size_t, Admin::AdminOptions, Queue], :void
    attach_function :rd_kafka_AlterConfigs_result_resources, [Event, :pointer], :pointer

    ## Resource Type (enum)
    attach_function :rd_kafka_ResourceType_name, [:resource_type], :string

    ## ConfigResource
    attach_function :rd_kafka_ConfigResource_new, [:resource_type, :string], Admin::ConfigResource
    attach_function :rd_kafka_ConfigResource_set_config, [Admin::ConfigResource, :string, :string], :error_code
    attach_function :rd_kafka_ConfigResource_configs, [Admin::ConfigResource, :pointer], :pointer
    attach_function :rd_kafka_ConfigResource_type, [Admin::ConfigResource], :resource_type
    attach_function :rd_kafka_ConfigResource_name, [Admin::ConfigResource], :string
    attach_function :rd_kafka_ConfigResource_error, [Admin::ConfigResource], :error_code
    attach_function :rd_kafka_ConfigResource_error_string, [Admin::ConfigResource], :string
    attach_function :rd_kafka_ConfigResource_destroy, [Admin::ConfigResource], :void
    attach_function :rd_kafka_ConfigResource_destroy_array, [:pointer, :size_t], :void

    ## ConfigEntry
    attach_function :rd_kafka_ConfigEntry_name, [Admin::ConfigEntry], :string
    attach_function :rd_kafka_ConfigEntry_value, [Admin::ConfigEntry], :string
    attach_function :rd_kafka_ConfigEntry_source, [Admin::ConfigEntry], :config_source
    attach_function :rd_kafka_ConfigEntry_is_read_only, [Admin::ConfigEntry], :int
    attach_function :rd_kafka_ConfigEntry_is_default, [Admin::ConfigEntry], :int
    attach_function :rd_kafka_ConfigEntry_is_sensitive, [Admin::ConfigEntry], :int
    attach_function :rd_kafka_ConfigEntry_is_synonym, [Admin::ConfigEntry], :int
    attach_function :rd_kafka_ConfigEntry_synonyms, [Admin::ConfigEntry, :pointer], :pointer

    ## ConfigSource
    attach_function :rd_kafka_ConfigSource_name, [:config_source], :string

    ## Create Topics / NewTopic
    attach_function :rd_kafka_CreateTopics, [Client, :pointer, :size_t, Admin::AdminOptions, Queue], :void, blocking: true
    attach_function :rd_kafka_CreateTopics_result_topics, [Event, :pointer], :pointer
    attach_function :rd_kafka_NewTopic_new, [:topic, :int, :int, :pointer, :size_t], Admin::NewTopic
    attach_function :rd_kafka_NewTopic_set_replica_assignment, [Admin::NewTopic, :partition, :pointer, :size_t, :pointer, :size_t], :error_code
    attach_function :rd_kafka_NewTopic_set_config, [Admin::NewTopic, :string, :string], :error_code
    attach_function :rd_kafka_NewTopic_destroy, [Admin::NewTopic], :void
    attach_function :rd_kafka_NewTopic_destroy_array, [:pointer, :size_t], :void

    # TopicResult
    attach_function :rd_kafka_topic_result_error, [Admin::TopicResult], :error_code
    attach_function :rd_kafka_topic_result_error_string, [Admin::TopicResult], :string
    attach_function :rd_kafka_topic_result_name, [Admin::TopicResult], :topic

    # DeleteTopics / DeleteTopic
    attach_function :rd_kafka_DeleteTopics, [Client, :pointer, :size_t, Admin::AdminOptions, Queue], :void
    attach_function :rd_kafka_DeleteTopics_result_topics, [Event, :pointer], :pointer
    attach_function :rd_kafka_DeleteTopic_new, [:topic], Admin::DeleteTopic
    attach_function :rd_kafka_DeleteTopic_destroy, [Admin::DeleteTopic], :void
    attach_function :rd_kafka_DeleteTopic_destroy_array, [:pointer, :size_t], :void

    # CreatePartitions / NewPartitions
    attach_function :rd_kafka_CreatePartitions, [Client, :pointer, :size_t, Admin::AdminOptions, Queue], :void
    attach_function :rd_kafka_CreatePartitions_result_topics, [Event, :pointer], :pointer

    attach_function :rd_kafka_NewPartitions_new, [:topic, :size_t, :pointer, :size_t], Admin::NewPartitions

    attach_function :rd_kafka_NewPartitions_set_replica_assignment, [Admin::NewPartitions, :partition, :pointer, :size_t, :pointer, :size_t], :error_code

    attach_function :rd_kafka_NewPartitions_destroy, [Admin::NewPartitions], :void
    attach_function :rd_kafka_NewPartitions_destroy_array, [:pointer, :size_t], :void
  end
end
