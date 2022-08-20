# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "kafka/consumer"

RSpec.describe Kafka::Consumer do
  it "can consume messages from a topic" do
    consumer = Kafka::Consumer.new(config)

    with_topic do |topic|
      consumer.subscribe(topic)

      publish(topic, "test", headers: { "foo" => "bar" })

      wait_for_assignments(consumer, topic: topic)

      received =
        consumer.poll(timeout: 5000) do |msg|
          expect(msg.payload).to eq("test")
          expect(msg.headers.get("foo")).to eq("bar")

          true
        end

      expect(received).to be(true)
    ensure
      consumer.close
    end
  end

  specify "#closed?" do
    consumer = Kafka::Consumer.new(config)

    expect { consumer.close }
      .to change(consumer, :closed?).from(false).to(true)
  end
end
