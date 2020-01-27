# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI do
  specify "#features" do
    features = Kafka::FFI.features
    expect(features).not_to be_empty
    expect(features).to include("ssl")
  end

  specify ".rd_kafka_msg_partitioner_random" do
    client = Kafka::FFI::Producer.new(config)

    with_topic(partitions: 5) do |topic|
      t = client.topic(topic)

      part = Kafka::FFI.rd_kafka_msg_partitioner_random(t, "key", 3, 5, nil, nil)
      expect(part).to be < 5
      expect(part).to be >= 0
    end
  ensure
    client.destroy
  end

  specify ".rd_kafka_msg_partitioner_consistent" do
    client = Kafka::FFI::Producer.new(config)

    with_topic(partitions: 5) do |topic|
      t = client.topic(topic)

      part = Kafka::FFI.rd_kafka_msg_partitioner_consistent(t, "key", 3, 5, nil, nil)
      expect(part).to eq(2)

      # nil / empty key is always assigned partition 0
      part = Kafka::FFI.rd_kafka_msg_partitioner_consistent(t, nil, 0, 5, nil, nil)
      expect(part).to eq(0)
    end
  ensure
    client.destroy
  end

  specify ".rd_kafka_msg_partitioner_consistent_random" do
    client = Kafka::FFI::Producer.new(config)

    with_topic(partitions: 5) do |topic|
      t = client.topic(topic)

      part = Kafka::FFI.rd_kafka_msg_partitioner_consistent_random(t, "key", 3, 5, nil, nil)
      expect(part).to eq(2)

      # nil / empty key is assigned a random partition
      part = Kafka::FFI.rd_kafka_msg_partitioner_consistent_random(t, nil, 0, 5, nil, nil)
      expect(part).to be < 5
      expect(part).to be >= 0
    end
  ensure
    client.destroy
  end

  specify ".rd_kafka_msg_partitioner_murmur2" do
    client = Kafka::FFI::Producer.new(config)

    with_topic(partitions: 5) do |topic|
      t = client.topic(topic)

      part = Kafka::FFI.rd_kafka_msg_partitioner_murmur2(t, "keykay", 6, 5, nil, nil)
      expect(part).to eq(2)

      # nil / empty key is always assigned partition 1
      part = Kafka::FFI.rd_kafka_msg_partitioner_murmur2(t, nil, 0, 5, nil, nil)
      expect(part).to eq(1)
    end
  ensure
    client.destroy
  end

  specify ".rd_kafka_msg_partitioner_murmur2_random" do
    client = Kafka::FFI::Producer.new(config)

    with_topic(partitions: 5) do |topic|
      t = client.topic(topic)

      part = Kafka::FFI.rd_kafka_msg_partitioner_murmur2_random(t, "key", 3, 5, nil, nil)
      expect(part).to eq(1)

      # nil / empty key is assigned a random partition
      part = Kafka::FFI.rd_kafka_msg_partitioner_murmur2_random(t, nil, 0, 5, nil, nil)
      expect(part).to be < 5
      expect(part).to be >= 0
    end
  ensure
    client.destroy
  end
end
