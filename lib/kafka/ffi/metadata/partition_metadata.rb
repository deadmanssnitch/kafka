# frozen_string_literal: true

class Kafka::FFI::Metadata
  class PartitionMetadata < ::FFI::Struct
    layout(
      :id,          :int32,
      :err,         :error_code,
      :leader,      :int32,
      :replica_cnt, :int,
      :replicas,    :pointer, # *int32_t
      :isr_cnt,     :int,
      :isrs,        :pointer  # *int32_t
    )

    # Returns the Partition's ID
    #
    # @return [Integer] Partition ID
    def id
      self[:id]
    end

    # Returns the error for the Partition as reported by the Broker.
    #
    # @return [nil] No error reported by Broker
    # @return [ResponseError] Error reported by Broker
    def error
      if self[:err] != :ok
        return Kafka::FFI::ResponseError.new(self[:err])
      end
    end

    # ID of the Leader Broker for this Partition
    #
    # @return [Integer] Leader Broker ID
    def leader
      self[:leader]
    end

    # Returns the Broker IDs of the Brokers with replicas of this Partition.
    #
    # @return [Array<Integer>] IDs for Brokers with replicas
    def replicas
      if self[:replica_cnt] == 0 || self[:replicas].null?
        return []
      end

      self[:replicas].read_array_of_int32(self[:replica_cnt])
    end

    # Returns the Broker IDs of the in-sync replicas for this Partition.
    #
    # @return [Array<Integer>] IDs of Brokers that have in-sync replicas.
    def in_sync_replicas
      if self[:isr_cnt] == 0 || self[:isrs].null?
        return []
      end

      self[:isrs].read_array_of_int32(self[:isr_cnt])
    end
  end
end
