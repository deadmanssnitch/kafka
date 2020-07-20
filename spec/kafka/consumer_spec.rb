# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "kafka/consumer"

RSpec.describe Kafka::Consumer do
  it "can consume messages from a topic" do
    consumer = Kafka::Consumer.new(config)

    with_topic do |topic|
      consumer.subscribe(topic)

      publish(topic, "test")

      wait_for_assignments(consumer, topic: topic)

      received =
        consumer.poll(timeout: 5000) do |msg|
          expect(msg.payload).to eq("test")

          true
        end

      expect(received).to be(true)
    ensure
      consumer.close
    end
  end
end
