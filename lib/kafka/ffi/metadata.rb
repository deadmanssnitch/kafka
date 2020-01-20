# frozen_string_literal: true

module Kafka::FFI
  class Metadata < ::FFI::Struct
    layout(
      :broker_cnt,       :int,
      :brokers,          :pointer, # *rd_kafka_metadata_broker
      :topic_cnt,        :int,
      :topics,           :pointer, # *rd_kafka_metadata_topic
      :orig_broker_id,   :int32,
      :orig_broker_name, :string
    )

    # Returns detailed metadata for the Brokers in the cluster.
    #
    # @return [Array<BrokerMetadata>] Metadata about known Brokers.
    def brokers
      ptr = self[:brokers]

      self[:broker_cnt].times.map do |i|
        BrokerMetadata.new(ptr + (i * BrokerMetadata.size))
      end
    end

    # Returns detailed metadata about the topics and their partitions.
    #
    # @return [Array<TopicMetadata>] Metadata about known Topics.
    def topics
      ptr = self[:topics]

      self[:topic_cnt].times.map do |i|
        TopicMetadata.new(ptr + (i * TopicMetadata.size))
      end
    end

    # Returns the ID of the Broker that the metadata request was served by.
    #
    # @return [Integer] Broker ID
    def broker_id
      self[:orig_broker_id]
    end

    # Returns the name of the Broker that the metadata request was served by.
    #
    # @return [String] Broker name
    def broker_name
      self[:orig_broker_name]
    end

    # Destroy the Metadata response, returning it's resources back to the
    # system.
    def destroy
      if !null?
        ::Kafka::FFI.rd_kafka_metadata_destroy(self)
      end
    end
  end
end
