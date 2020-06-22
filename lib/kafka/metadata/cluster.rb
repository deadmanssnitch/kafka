# frozen_string_literal: true

module Kafka::Metadata
  # Cluster provides detailed information about the Kafka cluster including the
  # Brokers that form the cluster and the topics that are hosted on the
  # cluster.
  class Cluster
    # Returns the ID of the Broker that served the metadata request.
    #
    # @return [Integer] ID of the Broker that served the metadata request.
    attr_reader :broker_id

    # Returns the name of the Broker that served the metadata request.
    #
    # @return [String] Broker name
    attr_reader :broker_name

    # Returns detailed metadata about the Brokers in the cluster.
    #
    # @return [Array<Kafka::Metadata::Broker>] Metadata about brokers in the
    #   Kafka cluster.
    attr_reader :brokers

    # Returns detailed metadata about the Topics (or requested Topics) in the
    # cluster and their Partitions.
    #
    # @return [Array<Kafka::Metadata::Topic>] Metadata about known topics in
    #   the cluster.
    attr_reader :topics

    # @param [Kafka::FFI::Metadata]
    def initialize(native)
      @broker_id = native.broker_id
      @broker_name = native.broker_name

      @brokers = native.brokers.map { |b| Broker.new(b) }
      @topics  = native.topics.map  { |t| Topic.new(t) }
    end

    # Find the metadata for the topic with the given name.
    #
    # @return [Kafka::Metadata::Topic, nil] Topic metadata or nil if there is
    #   no topic with that name was found in the metadata response.
    def topic(name)
      @topics.find { |t| t.name == name }
    end
  end
end
