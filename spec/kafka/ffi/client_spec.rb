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

  specify "#metadata" do
    client = Kafka::FFI::Client.new(:consumer, config)

    md = client.metadata(topic: "__consumer_offsets")
    expect(md).to be_a(Kafka::FFI::Metadata)
    expect(md.topics.size).to eq(1)
  ensure
    md.destroy
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
