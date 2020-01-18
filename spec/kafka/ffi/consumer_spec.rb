# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Consumer do
  specify "new" do
    consumer = Kafka::FFI::Consumer.new(config)
    expect(consumer).to be_a(Kafka::FFI::Consumer)
  ensure
    consumer.destroy if consumer
  end

  specify "#subscribe" do
    consumer = Kafka::FFI::Consumer.new(config)

    # With no subscriptions
    subs = consumer.subscription
    expect(subs.size).to eq(0)

    # Subscribe to multiple topics
    consumer.subscribe("topic", "snitches")

    subs = consumer.subscription
    expect(subs.size).to eq(2)
    expect(subs).to include("topic")
    expect(subs).to include("snitches")
  ensure
    consumer.destroy
  end

  # Subscribe replacing existing subscriptions was a surprise, so documenting
  # it here.
  specify "#subscribe replaces existing" do
    consumer = Kafka::FFI::Consumer.new(config)

    consumer.subscribe("topic")
    expect(consumer.subscription).to eq(["topic"])

    consumer.subscribe("events")
    expect(consumer.subscription).to eq(["events"])
  ensure
    consumer.destroy
  end

  specify "#subscribe with bad topic list" do
    consumer = Kafka::FFI::Consumer.new(config)

    expect { consumer.subscribe("") }
      .to raise_error(Kafka::ResponseError)
  ensure
    consumer.destroy
  end

  specify "#subscription with no subscriptions" do
    consumer = Kafka::FFI::Consumer.new(config)

    # With no subscriptions
    subs = consumer.subscription
    expect(subs.size).to eq(0)
  ensure
    consumer.destroy
  end

  specify "#subscription will flatten arrays" do
    consumer = Kafka::FFI::Consumer.new(config)

    # Could occur taking list of topics directly from other method returns.
    consumer.subscribe(["topic"], "foo", "bar", ["baz"])

    subs = consumer.subscription
    expect(subs).to match(%w[topic foo bar baz])
  ensure
    consumer.destroy
  end

  specify "#subscription" do
    consumer = Kafka::FFI::Consumer.new(config)
    consumer.subscribe("topic", "snitches")

    # Retrieves the list of subscriptions
    subs = consumer.subscriptions
    expect(subs.size).to eq(2)
    expect(subs).to match(["topic", "snitches"])
  ensure
    consumer.destroy
  end

  specify "#unsubscribe" do
    consumer = Kafka::FFI::Consumer.new(config)

    # Successful even when there are no existing subscriptions.
    consumer.unsubscribe

    consumer.subscribe("foo", "bar", "baz")

    # Removes all subscriptions
    expect { consumer.unsubscribe }
      .to change { consumer.subscription.count }.from(3).to(0)
  ensure
    consumer.destroy
  end

  specify "#assign" do
    consumer = Kafka::FFI::Consumer.new(config)

    with_topic(partitions: 9) do |topic|
      consumer.subscribe(topic)

      list = Kafka::FFI::TopicPartitionList.new
      list.add_range(topic, 0..3)

      consumer.assign(list)

      assigned = consumer.assignment
      expect(assigned).to eq({ topic => [0, 1, 2, 3] })
    ensure
      list.destroy
    end
  ensure
    consumer.destroy
  end

  specify "#assignment" do
    consumer = Kafka::FFI::Consumer.new(config)

    with_topic(partitions: 6) do |topic|
      list = Kafka::FFI::TopicPartitionList.new
      list.add(topic, 0)
      list.add(topic, 4)
      list.add(topic, 99)
      consumer.assign(list)

      assigned = consumer.assignment
      expect(assigned).to eq({ topic => [0, 4, 99] })
    ensure
      list.destroy
    end
  ensure
    consumer.destroy
  end

  specify "#committed" do
    consumer = Kafka::FFI::Consumer.new(config)

    with_topic(partitions: 2) do |topic|
      list = Kafka::FFI::TopicPartitionList.new
      list.add(topic, 1)

      # Short timeout to force a timeout error
      expect { consumer.committed(list, timeout: 1) }
        .to raise_error(Kafka::ResponseError, "Local: Timed out")

      # Actually takes about 1s locally
      consumer.committed(list, timeout: 2000)

      # In this test setup there are no committed offsets
      list.find(topic, 1).tap do |tp|
        expect(tp.offset).to eq(Kafka::FFI::RD_KAFKA_OFFSET_INVALID)
        expect(tp.error).to eq(nil)
      end
    ensure
      list.destroy
    end
  ensure
    consumer.destroy
  end

  specify "#get_consumer_queue" do
    client = Kafka::FFI::Consumer.new(config)

    queue = client.get_consumer_queue
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy
  end

  specify "#get_partition_queue" do
    client = Kafka::FFI::Consumer.new(config)

    queue = client.get_partition_queue("test", 1)
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy
  end
end
