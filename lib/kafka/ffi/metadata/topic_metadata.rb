# frozen_string_literal: true

class Kafka::FFI::Metadata
  class TopicMetadata < ::FFI::Struct
    layout(
      :topic,         :string,
      :partition_cnt, :int,
      :partitions,    :pointer, # *rd_kafka_metadata_partition
      :err,           :error_code
    )

    # Returns the name of the topic
    #
    # @return [String] Name of the topic
    def topic
      self[:topic]
    end
    alias name topic

    # Returns any Broker reported errors.
    #
    # @return [nil] Broker reported no errors for the topic
    # @return [Kafka::ResponseError] Error reported by Broker
    def error
      if self[:err] != :ok
        return ::Kafka::ResponseError.new(self[:err])
      end
    end

    # Returns the set of PartitionMetadata for the Topic
    #
    # @return [Array<PartitionMetadata>] Details about individual Topic
    #   Partitions.
    def partitions
      ptr = self[:partitions]

      self[:partition_cnt].times.map do |i|
        PartitionMetadata.new(ptr + (i * PartitionMetadata.size))
      end
    end
  end
end
