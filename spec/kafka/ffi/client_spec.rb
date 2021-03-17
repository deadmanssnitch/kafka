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

  specify "#name" do
    client = Kafka::FFI::Client.new(:producer, config)
    expect(client.name).to include("producer-")
  ensure
    client.destroy
  end

  specify "#cluster_id" do
    client = Kafka::FFI::Client.new(:producer, config)

    # Mainly validate that the call is correct since the value can't be
    # determined before hand.
    expect(client.cluster_id).not_to be_empty
  ensure
    client.destroy
  end

  specify "#controller_id" do
    client = Kafka::FFI::Client.new(:producer, config)

    # https://issues.apache.org/jira/browse/KAFKA-1070
    expect(client.controller_id).to be_a(Integer)
    expect(client.controller_id).to be >= 1001
  ensure
    client.destroy
  end

  specify "#topic" do
    client = Kafka::FFI::Client.new(:producer, config)

    with_topic do |topic|
      cfg = Kafka::FFI::TopicConfig.new
      cfg.set("auto.commit.enable", false)

      # First call to configure a topic
      t = client.topic(topic, cfg)
      expect(t).not_to be(nil)

      # It is an error to try and reconfigure a topic.
      expect { client.topic(topic, cfg) }
        .to raise_error(Kafka::FFI::TopicAlreadyConfiguredError)

      # Cached topic is always returned
      expect(client.topic(topic)).to be(t)
    end
  ensure
    client.destroy
  end

  specify "#metadata" do
    client = Kafka::FFI::Client.new(:consumer, config)

    with_topic(partitions: 2) do |name|
      md = client.metadata(topic: name)
      expect(md).to be_a(Kafka::Metadata::Cluster)
      expect(md.topics.size).to eq(1)

      expect(md.broker_id).to be >= 1001
      expect(md.broker_name).to match(/127\.0\.0\.1:9092\/\d+/)
      expect(md.brokers.size).to eq(1)

      md.brokers.first.tap do |broker|
        expect(broker.id).to be >= 1001
        expect(broker.host).to eq("127.0.0.1")
        expect(broker.port).to eq(9092)
      end

      topic = md.topic(name)
      expect(topic).not_to be(nil)
      expect(topic.name).to eq(name)
      expect(topic.partitions.size).to eq(2)
      expect(topic.error).to be(nil)
      expect(topic.error?).to be(false)

      topic.partitions.each_with_index do |part, index|
        expect(part.id).to eq(index)
        expect(part.error).to be(nil)
        expect(part.error?).to be(false)
        expect(part.leader).to be >= 1001

        expect(part.replicas.size).to eq(1)
        expect(part.replicas[0]).to be >= 1001

        expect(part.in_sync_replicas.size).to eq(1)
        expect(part.in_sync_replicas[0]).to be >= 1001
      end
    end
  ensure
    client.destroy
  end

  specify "#group_list" do
    cfg = config("group.id": "group_list_test", "client.id": "test_list_group")
    client = Kafka::FFI::Client.new(:consumer, cfg)

    with_topic do |topic|
      client.subscribe(topic)
      wait_for_assignments(client)

      groups = client.group_list(timeout: 10000)
      expect(groups).not_to be(nil)
      expect(groups).not_to be_empty

      info = groups.find { |g| g.name == "group_list_test" }
      expect(info).not_to be(nil)
      expect(info.error?).to be(false)
      expect(info.name).to eq("group_list_test")
      expect(info.state).to eq("Stable")
      expect(info.protocol).to eq("range")
      expect(info.protocol_type).to eq("consumer")
      expect(info.members).not_to be_empty

      info.broker.tap do |broker|
        expect(broker.id).to be >= 1001
        expect(broker.host).to eq("127.0.0.1")
        expect(broker.port).to eq(9092)
      end

      member = info.members[0]
      expect(member).not_to be(nil)
      expect(member.member_id).to start_with("test_list_group-")
      expect(member.client_id).to eq("test_list_group")

      # Will be the IP address of the current host
      expect(member.client_host).not_to be_empty

      # Binary encoded membership information. Just test that it's set
      # correctly.
      expect(member.member_metadata).not_to be_empty
      expect(member.member_assignment).not_to be_empty
    end
  ensure
    client.destroy
  end

  specify "#default_topic_conf_dup" do
    client = Kafka::FFI::Client.new(:consumer, config)

    topic_conf = client.default_topic_conf_dup
    expect(topic_conf).not_to be(nil)
    expect(topic_conf.get("auto.commit.enable")).to eq("true")
  ensure
    client.destroy
  end

  specify "#outq_len" do
    client = Kafka::FFI::Client.new(:consumer, config)

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
      expect(result).to be_a(Kafka::FFI::Admin::CreateTopicsResult)
      expect(result).to be_successful

      res = result.topics
      expect(res.length).to eq(2)
      expect(res.map(&:error)).to eq([nil, nil])
      expect(res.map(&:name)).to contain_exactly(*topics)
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
    expect(result).to be_a(Kafka::FFI::Admin::DeleteTopicsResult)
    expect(result).to be_successful

    result.topics.tap do |topics|
      expect(topics.size).to eq(1)
      expect(topics[0].error.name).to eq("RD_KAFKA_RESP_ERR_UNKNOWN_TOPIC_OR_PART")
    end
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
      expect(result).to be_a(Kafka::FFI::Admin::DeleteTopicsResult)
      expect(result).to be_successful

      result.topics.tap do |topics|
        expect(topics.length).to eq(1)
        expect(topics[0].topic).to eq(topic)
        expect(topics[0].error).to eq(nil)
      end
    ensure
      result.destroy
      delete.destroy
    end
  ensure
    client.destroy
  end

  specify "#delete_groups" do
    client = Kafka::FFI::Client.new(:producer, config)

    with_topic(partitions: 1) do |topic|
      group = SecureRandom.uuid

      publish(topic, "payload")
      consume(group, topic)

      begin
        delete = Kafka::FFI::Admin::DeleteGroup.new(group)

        result = client.delete_groups(delete)
        expect(result).to be_a(Kafka::FFI::Admin::DeleteGroupsResult)
        expect(result).to be_successful

        groups = result.groups
        expect(groups.size).to eq(1)
        expect(groups[0].name).to eq(group)
        expect(groups[0].error).to be(nil)
        expect(groups[0].partitions).to be(nil)
      ensure
        delete.destroy
        result.destroy
      end
    end
  ensure
    client.destroy
  end

  specify "#delete_groups error" do
    group = SecureRandom.uuid
    client = Kafka::FFI::Client.new(:consumer, config)

    begin
      delete = Kafka::FFI::Admin::DeleteGroup.new(group)

      result = client.delete_groups(delete)
      expect(result).to be_a(Kafka::FFI::Admin::DeleteGroupsResult)
      expect(result).to be_successful # error is per group

      result.groups.tap do |groups|
        expect(groups.size).to eq(1)
        expect(groups[0].error).not_to be(nil)
        expect(groups[0].name).to eq(group)
        expect(groups[0].error.code).to eq(Kafka::FFI::RD_KAFKA_RESP_ERR_GROUP_ID_NOT_FOUND)
      end
    ensure
      result.destroy
      delete.destroy
    end
  ensure
    client.destroy
  end

  specify "#delete_records" do
    client = Kafka::FFI::Client.new(:producer, config)

    with_topic(partitions: 1) do |topic|
      5.times { |i| publish(topic, "payload: #{i}") }

      client.metadata(local_only: false)

      begin
        tpl = Kafka::FFI::TopicPartitionList.new
        tpl.add(topic, 0)
        tpl.set_offset(topic, 0, 3)

        op = Kafka::FFI::Admin::DeleteRecords.new(tpl)

        result = client.delete_records(op)
        expect(result).to be_a(Kafka::FFI::Admin::DeleteRecordsResult)
        expect(result).to be_successful

        offsets = result.offsets
        expect(offsets.elements.size).to eq(1)

        offsets.find(topic, 0).tap do |tp|
          expect(tp.error).to be(nil)
          expect(tp.offset).to eq(3)
        end
      ensure
        result.destroy
        tpl.destroy
        op.destroy
      end
    end
  ensure
    client.destroy
  end

  specify "#delete_consumer_group_offsets" do
    group = SecureRandom.uuid
    client = Kafka::FFI::Client.new(:consumer, config("group.id" => group))

    with_topic(partitions: 1) do |topic|
      # Publish and consume from the topic to ensure an offset is committed.
      publish(topic, "payload")
      consume(group, topic)

      # check the committed offset
      begin
        tpl = Kafka::FFI::TopicPartitionList.new
        tpl.add(topic, 0)

        res = client.committed(tpl)
        expect(res.elements.size).to eq(1)
        expect(res.elements[0].offset).to eq(1)
      ensure
        tpl.destroy
      end

      # delete the committed offset
      begin
        tpl = Kafka::FFI::TopicPartitionList.new
        tpl.add(topic, 0)

        delete = Kafka::FFI::Admin::DeleteConsumerGroupOffsets.new(group, tpl)

        result = client.delete_consumer_group_offsets(delete)
        expect(result).to be_a(Kafka::FFI::Admin::DeleteConsumerGroupOffsetsResult)
        expect(result).to be_successful

        result.groups.tap do |groups|
          expect(groups.length).to eq(1)
          expect(groups[0].name).to eq(group)
          expect(groups[0].error).to eq(nil)

          # Response will return the offset as being invalid
          expect(groups[0].partitions).not_to be(nil)
          expect(groups[0].partitions.find(topic, 0).offset).to eq(Kafka::FFI::RD_KAFKA_OFFSET_INVALID)
        end
      ensure
        tpl.destroy
        delete.destroy
        result.destroy
      end

      # verify that the delete succeeded
      begin
        tpl = Kafka::FFI::TopicPartitionList.new
        tpl.add(topic, 0)

        m = client.committed(tpl)
        expect(m.elements.first.offset).to eq(Kafka::FFI::RD_KAFKA_OFFSET_INVALID)
      ensure
        tpl.destroy
      end
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
      expect(result).to be_a(Kafka::FFI::Admin::CreatePartitionsResult)
      expect(result).to be_successful

      result.topics.tap do |topics|
        expect(topics.size).to eq(1)
        expect(topics[0].error).to be(nil)
      end

      tp = client.metadata.topic(topic)
      expect(tp).not_to be(nil)
      expect(tp.partitions.size).to eq(3)
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
      expect(result).to be_a(Kafka::FFI::Admin::AlterConfigsResult)
      expect(result).to be_successful

      result.resources.tap do |resources|
        expect(resources.size).to eq(1)
        expect(resources[0].name).to eq(topic)
      end
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

      result = client.describe_configs(resource)
      expect(result).to be_a(Kafka::FFI::Admin::DescribeConfigsResult)

      result.resources.tap do |resources|
        expect(resources.size).to eq(1)
        expect(resources[0].name).to eq(topic)
      end
    ensure
      resource.destroy
      result.destroy
    end
  ensure
    client.destroy
  end

  specify "#get_main_queue" do
    client = Kafka::FFI::Client.new(:producer, config)

    queue = client.get_main_queue
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#get_background_queue is nil with no configured background_event_cb" do
    client = Kafka::FFI::Client.new(:producer, config)

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
