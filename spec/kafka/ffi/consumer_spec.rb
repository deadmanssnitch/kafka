# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Consumer do
  specify "new" do
    consumer = Kafka::FFI::Consumer.new(config.native)
    expect(consumer).to be_a(Kafka::FFI::Consumer)
  ensure
    consumer.destroy if consumer
  end

  specify "#subscribe" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    # With no subscriptions
    tpl = consumer.subscription
    expect(tpl.size).to eq(0)

    list = Kafka::FFI::TopicPartitionList.new
    list.add("topic")
    list.add("snitches", 5)
    expect(consumer.subscribe(list)).to eq(nil)

    tpl = consumer.subscription
    expect(tpl.size).to eq(2)
    expect(tpl.find("topic", -1)).not_to be(nil)
    expect(tpl.find("snitches", 5)).not_to be(nil)
  ensure
    consumer.destroy
    list.destroy if list
  end

  specify "#subscribe with bad topic list" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    list = Kafka::FFI::TopicPartitionList.new
    list.add("")
    expect { consumer.subscribe(list) }
      .to raise_error(Kafka::FFI::ResponseError)
  ensure
    consumer.destroy
    list.destroy
  end

  specify "#subscription with no subscriptions" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    # With no subscriptions
    tpl = consumer.subscription
    expect(tpl.size).to eq(0)
  ensure
    tpl.destroy if tpl
    consumer.destroy if consumer
  end

  specify "#subscription" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    list = Kafka::FFI::TopicPartitionList.new
    list.add("topic")
    list.add("snitches", 5)
    consumer.subscribe(list)

    # Retrieves the list of subscriptions
    tpl = consumer.subscription
    expect(tpl.size).to eq(2)
    expect(tpl.find("topic", -1)).not_to be(nil)
    expect(tpl.find("snitches", 5)).not_to be(nil)
  ensure
    tpl.destroy if tpl
    consumer.destroy if consumer
  end

  specify "#unsubscribe" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    # Successful even when there are no existing subscriptions.
    consumer.unsubscribe

    begin
      list = Kafka::FFI::TopicPartitionList.new
      list.add_range("topic", 1..10)
      consumer.subscribe(list)
    ensure
      list.destroy
    end

    # Removes all subscriptions
    consumer.unsubscribe

    tpl = consumer.subscription
    expect(tpl).to be_empty
  ensure
    tpl.destroy if tpl
    consumer.destroy if consumer
  end

  specify "#assign" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    list = Kafka::FFI::TopicPartitionList.new
    list.add_range("topic", 1..10)
    consumer.subscribe(list)

    # Just verifies that calling `assign` doesn't explode. At this level it's
    # impossible to verify that assignments are happening. It will be checked
    # at the integration level.
    consumer.assign(list)
  ensure
    consumer.destroy
    list.destroy
  end

  specify "#assignment" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    list = Kafka::FFI::TopicPartitionList.new
    list.add_range("topic", 1..10)
    consumer.subscribe(list)

    # Just verifies that calling `assignment` doesn't explode. At this level
    # it's impossible to verify that assignments are happening. It will be
    # checked at the integration level.
    begin
      tpl = consumer.assignment
      expect(tpl).to be_empty
    ensure
      tpl.destroy
    end
  ensure
    consumer.destroy if consumer
    list.destroy if list
  end

  specify "#committed" do
    consumer = Kafka::FFI::Consumer.new(config.native)

    with_topic(partitions: 2) do |topic|
      list = Kafka::FFI::TopicPartitionList.new
      list.add(topic, 1)

      # Short timeout to force a timeout error
      expect { consumer.committed(list, timeout: 1) }
        .to raise_error(Kafka::FFI::ResponseError, "Local: Timed out")

      # Actually takes about 1s locally
      consumer.committed(list, timeout: 2000)

      # In this test setup there are no committed offsets
      list.find(topic, 1).tap do |tp|
        expect(tp.offset).to eq(Kafka::FFI::RD_KAFKA_OFFSET_INVALID)
        expect(tp.error).to eq(nil)
      end
    ensure
      list.destroy if list
    end
  ensure
    consumer.destroy
  end

  specify "#get_consumer_queue" do
    client = Kafka::FFI::Consumer.new(config.native)

    queue = client.get_consumer_queue
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#get_partition_queue" do
    client = Kafka::FFI::Consumer.new(config.native)

    queue = client.get_partition_queue("test", 1)
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy if queue
  end
end
