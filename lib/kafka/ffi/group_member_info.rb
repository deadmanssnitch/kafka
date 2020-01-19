# frozen_string_literal: true

require "ffi"

module Kafka::FFI
  class GroupMemberInfo < ::FFI::Struct
    layout(
      :member_id,              :string,
      :client_id,              :string,
      :client_host,            :string,
      :member_metadata,        :pointer,
      :member_metadata_size,   :int,
      :member_assignment,      :pointer,
      :member_assignment_size, :int
    )

    # Returns the broker generated member id for the consumer.
    #
    # @return [String] Member ID
    def member_id
      self[:member_id]
    end

    # Returns the consumer's client.id config setting
    #
    # @return [String] Client ID
    def client_id
      self[:client_id]
    end

    # Returns the hostname of the consumer
    #
    # @return [String] Consumer's hostname
    def client_host
      self[:client_host]
    end

    # Returns the binary metadata for the consumer
    #
    # @return [String] Consumer metadata
    def member_metadata
      self[:member_metadata].read_string(self[:member_metadata_size])
    end

    # Returns the binary assignment data for the consumer
    #
    # @return [String] Assignments
    def member_assignment
      self[:member_assignment].read_string(self[:member_assignment_size])
    end
  end
end
