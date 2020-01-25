# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Client do
  specify "#config" do
    config = config("client.id": "test")

    client = Kafka::FFI::Client.new(:producer, config)
    expect(client.config.get("client.id")).to eq("test")
  ensure
    client.destroy
  end

  specify "#cluster_id" do
    client = Kafka::FFI::Client.new(:producer, config)

    # Mainly validate that the call is correct since the value can't be
    # determined before hand. rd_kafka_clusterid
    expect(client.cluster_id).not_to be_empty
  ensure
    client.destroy
  end

  specify "#metadata" do
    client = Kafka::FFI::Client.new(:consumer, config)

    md = client.metadata(topic: "__consumer_offsets")
    expect(md).to be_a(Kafka::FFI::Metadata)
    expect(md.topics.size).to eq(1)
  ensure
    md.destroy
    client.destroy
  end

  specify "#group_list" do
    cfg = config("group.id": "group_list_test", "client.id": "test_list_group")
    client = Kafka::FFI::Client.new(:consumer, cfg)

    with_topic do |topic|
      client.subscribe(topic)
      wait_for_assignments(client)

      list = client.group_list(timeout: 10000)
      expect(list).not_to be(nil)

      info = list.groups.find { |g| g.name == "group_list_test" }
      expect(info).not_to be(nil)

      member = info.members.find { |m| m.client_id == "test_list_group" }
      expect(member).not_to be(nil)
    ensure
      list.destroy if list
    end
  ensure
    client.destroy
  end

  specify "#default_topic_conf_dup" do
    client = Kafka::FFI::Client.new(:consumer)

    topic_conf = client.default_topic_conf_dup
    expect(topic_conf).not_to be(nil)
    expect(topic_conf.get("auto.commit.enable")).to eq("true")
  ensure
    client.destroy
  end

  specify "#outq_len" do
    client = Kafka::FFI::Client.new(:consumer)

    # Mainly ensure that we can call it and it returns a value. Not sure of a
    # good way to modify the outbound queue.
    expect(client.outq_len).to eq(0)
  ensure
    client.destroy
  end

  specify "#brokers_add" do
    # Default config does not have any brokers
    client = Kafka::FFI::Client.new(:producer, nil)

    expect(client.brokers_add("127.0.0.1:9092")).to eq(1)

    metadata = client.metadata
    expect(metadata.brokers.size).to eq(1)
    expect(metadata.brokers[0].host).to eq("127.0.0.1")
    expect(metadata.brokers[0].port).to eq(9092)
  ensure
    metadata.destroy if metadata
  end

  specify "#create_topics" do
    client = Kafka::FFI::Client.new(:producer, config)

    options = Kafka::FFI::Admin::AdminOptions.new(client, :create_topics)
    options.set_operation_timeout(2000) # Wait for propogation

    topics = [ SecureRandom.uuid, SecureRandom.uuid ]

    begin
      requests = [
        Kafka::FFI::Admin::NewTopic.new(topics[0], 3, 1),
        Kafka::FFI::Admin::NewTopic.new(topics[1], 1, 1),
      ]

      result = client.create_topics(requests, options: options)

      expect(result.length).to eq(2)
      expect(result.map(&:error)).to eq([nil, nil])
    ensure
      result.destroy
      requests.each(&:destroy)
    end
  ensure
    delete = topics.map { |n| Kafka::FFI::Admin::DeleteTopic.new(n) }
    client.delete_topics(delete)
    delete.each(&:destroy)

    options.destroy
    client.destroy
  end

  specify "#delete_topics topic does not exist" do
    client = Kafka::FFI::Client.new(:producer, config)
    topic = SecureRandom.uuid

    delete = Kafka::FFI::Admin::DeleteTopic.new(topic)
    result = client.delete_topics(delete)

    expect(result.size).to eq(1)
    expect(result.first.error.name).to eq("RD_KAFKA_RESP_ERR_UNKNOWN_TOPIC_OR_PART")
  ensure
    delete.destroy
    result.destroy
    client.destroy
  end

  specify "#delete_topics" do
    client = Kafka::FFI::Client.new(:producer, config)

    with_topic do |topic|
      delete = Kafka::FFI::Admin::DeleteTopic.new(topic)
      result = client.delete_topics(delete)

      expect(result.length).to eq(1)
      expect(result[0].topic).to eq(topic)
      expect(result[0].error).to eq(nil)
    ensure
      result.destroy
      delete.destroy
    end
  ensure
    client.destroy
  end

  specify "#create_partitions" do
    client = Kafka::FFI::Client.new(:producer, config)

    with_topic(partitions: 1) do |topic|
      request = Kafka::FFI::Admin::NewPartitions.new(topic, 3)

      options = Kafka::FFI::Admin::AdminOptions.new(client, :create_partitions)
      options.set_operation_timeout(2000) # Wait for propogation

      result = client.create_partitions(request, options: options)
      expect(result.size).to eq(1)
      expect(result[0].error).to be(nil)

      begin
        metadata = client.metadata

        tp = metadata.topics.find { |t| t.name == topic }
        expect(tp).not_to be(nil)
        expect(tp.partitions.size).to eq(3)
      ensure
        metadata.destroy
      end
    ensure
      request.destroy
      options.destroy
      result.destroy
    end
  ensure
    client.destroy
  end

  specify "#alter_confgs" do
    client = Kafka::FFI::Client.new(:producer, config)

    with_topic do |topic|
      resource = Kafka::FFI::Admin::ConfigResource.new(:topic, topic)

      result = client.alter_configs(resource)
      expect(result).not_to be(nil)
      expect(result.size).to eq(1)
    ensure
      resource.destroy
    end
  ensure
    client.destroy
  end

  specify "#describe_confgs" do
    client = Kafka::FFI::Client.new(:producer, config)

    with_topic do |topic|
      resource = Kafka::FFI::Admin::ConfigResource.new(:topic, topic)

      results = client.describe_configs(resource)
      expect(results).not_to be(nil)
      expect(results.size).to eq(1)
      expect(results[0].name).to eq(topic)
    ensure
      resource.destroy
      results.destroy
    end
  ensure
    client.destroy
  end

  specify "#get_main_queue" do
    client = Kafka::FFI::Client.new(:producer)

    queue = client.get_main_queue
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#get_background_queue is nil with no configured background_event_cb" do
    client = Kafka::FFI::Client.new(:producer)

    queue = client.get_background_queue
    expect(queue).to be(nil)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#set_log_queue" do
    # log.queue must be set to true otherwise segfault
    config = config("log.queue": true)

    client = Kafka::FFI::Client.new(:producer, config)
    queue = Kafka::FFI::Queue.new(client)

    # Redirect logs to the Queue
    expect(client.set_log_queue(queue)).to be(nil)

    # Redirect back to the main queue
    expect(client.set_log_queue(nil)).to be(nil)
  ensure
    client.destroy
    queue.destroy if queue
  end
end
