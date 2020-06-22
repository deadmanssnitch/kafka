# frozen_string_literal: true

class Kafka::Metadata
  class Partition
    # Returns the Partition's ID
    #
    # @return [Integer] Partition ID
    attr_reader :id

    # Returns the error for the Partition as reported by the Broker.
    #
    # @return [Kafka::ResponseError, nil] Error reported by the broker or nil
    #   if the metadata was retrieved successfully.
    attr_reader :error

    # Returns the ID of the Leader Broker for this Partition
    #
    # @return [Integer] Leader Broker ID
    attr_reader :leader

    # Returns the IDs of the Brokers that have replicas of this partition.
    #
    # @return [Array<Integer>] IDs of Brokers with replicas
    attr_reader :replicas

    # Returns the IDs of the Brokers that have in-sync replicas for this
    # Partition.
    #
    # @return [Array<Integer>] IDs of in-sync Brokers
    attr_reader :in_sync_replicas

    # @param native [Kafka::FFI::PartitionMetadata]
    def initialize(native)
      @id = native.id
      @error = native.error
      @leader = native.leader
      @replicas = native.replicas
      @in_sync_replicas = native.in_sync_replicas
    end

    # Returns true when retrieving Partition metadata failed
    #
    # @return [Boolean] True when there is an error for the Partition.
    def error?
      error != nil
    end
  end
end
