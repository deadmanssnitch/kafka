# frozen_string_literal: true

module Kafka::Metadata
  class Topic
    # Returns the name of the topic
    #
    # @return [String] Name of the topic
    attr_reader :name

    # Returns metadata for the partitions of the topic
    #
    # @return [Array<Kafka::Metadata::Partition>] Metadata for the Topic's
    #   Partitions.
    attr_reader :partitions

    # Returns the Broker reported error for the topic
    #
    # @return [Kafka::ResponseError, nil] Error reported by the Broker for this
    #   topic or nil if the metadata was retrieved successfully.
    attr_reader :error

    # @param native [Kafka::FFI::TopicMetadata]
    def initialize(native)
      @name = native.name
      @error = native.error
      @partitions = native.partitions.map { |p| Partition.new(p) }
    end

    # Returns true when retrieving the Topic metadata failed.
    #
    # @return [Boolean] True when there is an error for the Topic.
    def error?
      error != nil
    end
  end
end
