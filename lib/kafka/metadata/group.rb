# frozen_string_literal: true

class Kafka::Metadata
  class Group
    # Returns the name of the Group
    #
    # @return [string] Group name
    attr_reader :name

    # Returns any error associated for the Group as returned by the broker when
    # the group list was requested.
    #
    # @return [Kafka::ResponseError, nil] Error reported by the broker or nil
    #   if the group list was retrieved successfully.
    attr_reader :error

    # Returns metadata about the broker that replied to the group metadata request.
    #
    # @return [Kafka::Metadata::Broker] Broker metadata
    attr_reader :broker

    # Returns metadata of group members
    #
    # @return [Array<Kafka::Metadata::GroupMember>] Group member metadata
    attr_reader :members

    # Returns the current state of the group
    #
    # @return [String] Group state
    attr_reader :state

    # Returns the type of protocol used by the group
    #
    # @return [String] Group protocol type
    attr_reader :protocol_type

    # Returns the group protocol
    #
    # @see partition.assignment.strategy config option.
    #
    # @return [String] Group protocol
    attr_reader :protocol

    # @param native [Kafka::FFI::GroupInfo]
    def initialize(native)
      @name = native.group
      @error = native.error
      @state = native.state

      @protocol = native.protocol
      @protocol_type = native.protocol_type

      @broker  = Broker.new(native.broker)
      @members = native.members.map { |m| GroupMember.new(m) }
    end

    # Returns true when retrieving Partition metadata failed
    #
    # @return [Boolean] True when there is an error for the Partition.
    def error?
      error != nil
    end
  end
end
