# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "kafka/consumer"

RSpec.describe Kafka::Producer do
  it "can publish messages to a topic" do
    producer = Kafka::Producer.new(config)

    with_topic do |topic|
      # Publish a message and wait for it to be delivered
      result = producer.produce(topic, "[EXAMPLE CONTENT HERE]")
      result.wait(timeout: 5000)

      published = fetch(topic, count: 1)
      expect(published.length).to eq(1)
      expect(published[0].payload).to eq("[EXAMPLE CONTENT HERE]")
      expect(published[0].topic).to eq(result.topic)
      expect(published[0].offset).to eq(result.offset)
      expect(published[0].partition).to eq(result.partition)
      expect(published[0].latency).to be > 0
      expect(result.error).to be(nil)
    ensure
      producer.close
    end
  end

  specify "#produce takes a block for async delivery reports" do
    producer = Kafka::Producer.new(config)

    with_topic do |topic|
      # Publish a message and wait for it to be delivered
      reports = Queue.new

      result = producer.produce(topic, "[EXAMPLE CONTENT HERE]") do |report|
        reports << report
      end
      expect(result).to be_a(Kafka::Producer::DeliveryReport)

      result.wait

      async = Timeout.timeout(1) { reports.pop }
      expect(async).to be_successful
      expect(async.topic).to eq(topic)
      expect(async.offset).to eq(0)
      expect(async.partition).not_to be(nil)
      expect(async.latency).to be > 0

      # Same object is returned
      expect(async).to be(result)

      published = fetch(topic, count: 1)
      expect(published.length).to eq(1)
      expect(published[0].payload).to eq("[EXAMPLE CONTENT HERE]")
    ensure
      producer.close
    end
  end

  specify "#produce when queue is full" do
    producer = Kafka::Producer.new(config({
      # Small buffer so we can easily overflow it
      "queue.buffering.max.messages": 1,
    }))

    with_topic do |topic|
      expect { 10.times { producer.produce(topic, "") } }
        .to raise_error(Kafka::QueueFullError)
    ensure
      producer.close
    end
  end
end
