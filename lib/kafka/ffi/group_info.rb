# frozen_string_literal: true

require "ffi"
require "kafka/ffi/group_member_info"
require "kafka/ffi/metadata/broker_metadata"

module Kafka::FFI
  class GroupInfo < ::FFI::Struct
    layout(
      :broker,        Metadata::BrokerMetadata.by_value,
      :group,         :string,
      :err,           :error_code,
      :state,         :string,
      :protocol_type, :string,
      :protocol,      :string,
      :members,       :pointer,
      :member_cnt,    :int
    )

    # Returns information about the broker that originated the group info.
    #
    # @return [Kafka::FFI::Metadata::BrokerMetadata] Broker info
    def broker
      self[:broker]
    end

    # Returns the name of the group
    #
    # @return [String] Group name
    def group
      self[:group]
    end
    alias name group

    # Returns any broker orignated error for the consumer group.
    #
    # @return [nil] No error
    # @return [Kafka::ResponseError] Broker originated error
    def error
      if self[:err] != :ok
        ::Kafka::ResponseError.new(self[:err])
      end
    end

    # Returns the current state of the group
    #
    # @return [String] Group state
    def state
      self[:state]
    end

    # Returns the group protocol type
    #
    # @return [String] Group protocol type
    def protocol_type
      self[:protocol_type]
    end

    # Returns the group protocol
    #
    # @return [String] Group protocol
    def protocol
      self[:protocol]
    end

    # Returns information about the members of the consumer group
    #
    # @return [Array<GroupMemberInfo>] Member information
    def members
      self[:member_cnt].times.map do |i|
        GroupMemberInfo.new(self[:members] + (i * GroupMemberInfo.size))
      end
    end
  end
end
