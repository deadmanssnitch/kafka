# frozen_string_literal: true

module Kafka::Metadata
  class GroupMember
    # Returns the broker generated member id for the consumer.
    #
    # @return [String] Member ID
    attr_reader :member_id

    # Returns the consumer's client.id config setting
    #
    # @return [String] Client ID
    attr_reader :client_id

    # Returns the hostname of the consumer
    #
    # @return [String] Consumer's hostname
    attr_reader :client_host

    # Returns the binary metadata for the consumer
    #
    # @return [String] Consumer metadata
    attr_reader :member_metadata

    # Returns the binary assignment data for the consumer
    #
    # @return [String] Assignments
    attr_reader :member_assignment

    # @param native [Kafka::FFI::GroupMemberInfo]
    def initialize(native)
      @member_id = native.member_id
      @client_id = native.client_id
      @client_host = native.client_host
      @member_metadata = native.member_metadata
      @member_assignment = native.member_assignment
    end
  end
end
